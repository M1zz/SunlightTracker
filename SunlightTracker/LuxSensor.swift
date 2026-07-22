import Foundation
import AVFoundation
import Combine
import SwiftUI

/// 아이폰의 전면 카메라를 활용해 주변 조도(Lux)를 실시간 측정하는 센서
/// iOS에서 직접적인 Ambient Light Sensor API는 비공개이므로,
/// 카메라의 ISO/ExposureDuration 메타데이터로 Lux를 추정합니다.
class LuxSensor: NSObject, ObservableObject {
    
    // MARK: - Published
    @Published var currentLux: Double = 0
    @Published var isActive: Bool = false
    @Published var isSunlight: Bool = false          // 현재 햇빛 감지 여부
    @Published var lightLevel: LightLevel = .dark
    @Published var errorMessage: String?
    
    // MARK: - Settings
    var sunlightThresholdLux: Double = 1000  // 이 이상이면 "햇빛"으로 간주
    var outdoorThresholdLux: Double = 300    // 이 이상이면 "실외"로 간주
    
    // MARK: - Private
    private var captureSession: AVCaptureSession?
    private var videoOutput: AVCaptureVideoDataOutput?
    private let sessionQueue = DispatchQueue(label: "com.sunlighttracker.luxsensor")
    private var luxHistory: [Double] = []
    private let maxHistoryCount = 5  // 이동 평균용 (반응성과 부드러움 균형)
    private var frameCounter = 0
    private var framesToSkip = 15  // 0.5초마다 업데이트 (30fps 기준), 동적 조정됨
    private var smoothedValue: Double = 0  // EMA용 이전 값
    private let smoothingFactor: Double = 0.3  // 0에 가까울수록 더 부드러움

    // 스마트 센싱
    private var lastLuxValue: Double = 0
    private var stableReadingsCount = 0  // 안정적인 읽기 횟수
    private let stableThreshold = 20  // 20번 연속 변동 없으면 저빈도 모드
    private let luxChangeThreshold: Double = 50  // 50 lux 이상 변화하면 "변화 있음"으로 간주
    private var sensorStartTime: Date?  // 센서 시작 시간
    private let initialActiveSeconds: Double = 20  // 최초 활성 유지 시간 (초)
    private let maxFramesToSkip = 60  // 안정 시에도 최대 2초 간격 (30fps × 2초)
    
    enum LightLevel: String {
        case dark = "어두움"
        case indoor = "실내"
        case cloudy = "흐림/그늘"
        case outdoor = "실외"
        case sunlight = "햇빛"
        case brightSunlight = "강한 햇빛"
        
        var emoji: String {
            switch self {
            case .dark: return "🌑"
            case .indoor: return "💡"
            case .cloudy: return "☁️"
            case .outdoor: return "⛅"
            case .sunlight: return "☀️"
            case .brightSunlight: return "🔆"
            }
        }
        
        var color: String {
            switch self {
            case .dark: return "gray"
            case .indoor: return "yellow"
            case .cloudy: return "lightBlue"
            case .outdoor: return "cyan"
            case .sunlight: return "orange"
            case .brightSunlight: return "red"
            }
        }
    }
    
    // MARK: - Start / Stop
    func startSensing() {
        guard !isActive else { return }
        
        AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
            guard granted else {
                DispatchQueue.main.async {
                    self?.errorMessage = "카메라 권한이 필요합니다. 설정에서 허용해주세요."
                }
                return
            }
            self?.setupCaptureSession()
        }
    }
    
    func stopSensing() {
        sessionQueue.async { [weak self] in
            self?.captureSession?.stopRunning()
            DispatchQueue.main.async {
                self?.isActive = false
                self?.frameCounter = 0
                self?.smoothedValue = 0
                self?.luxHistory.removeAll()
                self?.lastLuxValue = 0
                self?.stableReadingsCount = 0
                self?.framesToSkip = 15  // 다시 시작할 때 빠른 모드로
                self?.sensorStartTime = nil  // 시작 시간 초기화
            }
        }
    }
    
    // MARK: - Setup
    private func setupCaptureSession() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            
            let session = AVCaptureSession()
            session.sessionPreset = .low  // 조도만 필요하므로 최저 해상도
            
            // 전면 카메라 사용 (화면을 보면서 자연스럽게 측정)
            guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else {
                DispatchQueue.main.async {
                    self.errorMessage = "카메라를 사용할 수 없습니다."
                }
                return
            }
            
            do {
                let input = try AVCaptureDeviceInput(device: device)
                if session.canAddInput(input) {
                    session.addInput(input)
                }
                
                let output = AVCaptureVideoDataOutput()
                output.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
                output.setSampleBufferDelegate(self, queue: self.sessionQueue)
                output.alwaysDiscardsLateVideoFrames = true
                
                if session.canAddOutput(output) {
                    session.addOutput(output)
                }
                
                self.captureSession = session
                self.videoOutput = output
                
                session.startRunning()

                DispatchQueue.main.async {
                    self.isActive = true
                    self.errorMessage = nil
                    self.sensorStartTime = Date()  // 센서 시작 시간 기록
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "카메라 초기화 실패: \(error.localizedDescription)"
                }
            }
        }
    }
    
    // MARK: - Lux Calculation
    private func calculateLux(from sampleBuffer: CMSampleBuffer) -> Double? {
        // 카메라 메타데이터에서 ExposureTime, ISO 추출
        guard let metadata = CMCopyDictionaryOfAttachments(
            allocator: nil,
            target: sampleBuffer,
            attachmentMode: kCMAttachmentMode_ShouldPropagate
        ) as? [String: Any] else { return nil }
        
        guard let exifData = metadata["{Exif}"] as? [String: Any] else { return nil }
        
        let exposureTime = exifData["ExposureTime"] as? Double ?? 0.01
        let fNumber = exifData["FNumber"] as? Double ?? 1.8
        let isoSpeed = exifData["ISOSpeedRatings"] as? [Double] ?? [100]
        let iso = isoSpeed.first ?? 100
        
        // EV (Exposure Value) 계산
        // EV = log2(f^2 / t) - log2(ISO/100)
        guard exposureTime > 0 else { return nil }
        
        let ev = log2(fNumber * fNumber / exposureTime) - log2(iso / 100.0)
        
        // EV -> Lux 변환 (근사값)
        // Lux ≈ 2.5 * 2^EV (경험적 보정 계수)
        let lux = 2.5 * pow(2.0, ev)
        
        return max(0, lux)
    }
    
    // MARK: - Light Level Classification
    private func classifyLightLevel(_ lux: Double) -> LightLevel {
        switch lux {
        case ..<50:
            return .dark
        case 50..<300:
            return .indoor
        case 300..<1000:
            return .cloudy
        case 1000..<10000:
            return .outdoor
        case 10000..<50000:
            return .sunlight
        default:
            return .brightSunlight
        }
    }
    
    /// 지수 이동 평균 (EMA)으로 부드러운 Lux 값 계산
    /// EMA = α * newValue + (1 - α) * previousEMA
    /// α가 작을수록 더 부드럽게 변화
    private func smoothedLux(_ newLux: Double) -> Double {
        // 첫 값은 그대로 사용
        if smoothedValue == 0 {
            smoothedValue = newLux
            return newLux
        }

        // 지수 이동 평균 계산
        smoothedValue = smoothingFactor * newLux + (1 - smoothingFactor) * smoothedValue
        return smoothedValue
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
extension LuxSensor: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        // 프레임 스킵: 동적 조정 (변동 없으면 1분에 1번)
        frameCounter += 1
        guard frameCounter >= framesToSkip else { return }
        frameCounter = 0

        guard let rawLux = calculateLux(from: sampleBuffer) else { return }

        // EMA로 부드러운 값 계산
        let lux = smoothedLux(rawLux)

        // 최초 20초 경과 확인
        let elapsedSeconds = sensorStartTime.map { Date().timeIntervalSince($0) } ?? 0
        let isInitialPeriod = elapsedSeconds < initialActiveSeconds

        // 변동량 감지 (최초 20초 이후부터만)
        if !isInitialPeriod {
            let luxChange = abs(lux - lastLuxValue)
            lastLuxValue = lux

            if luxChange < luxChangeThreshold {
                // 변동 없음
                stableReadingsCount += 1

                // 안정적이면 저빈도 모드 (최대 2초에 1번)
                if stableReadingsCount >= stableThreshold {
                    framesToSkip = maxFramesToSkip
                }
            } else {
                // 변동 감지됨 - 다시 빠른 모드로
                stableReadingsCount = 0
                framesToSkip = 15  // 0.5초마다
            }
        } else {
            // 최초 20초는 항상 빠른 모드 유지
            lastLuxValue = lux
            framesToSkip = 15  // 0.5초마다
        }

        // UI 업데이트는 애니메이션과 함께
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            // 0.4초 애니메이션으로 부드럽게 전환
            withAnimation(.easeInOut(duration: 0.4)) {
                self.currentLux = lux
                self.lightLevel = self.classifyLightLevel(lux)
                self.isSunlight = lux >= self.outdoorThresholdLux
            }
        }
    }
}

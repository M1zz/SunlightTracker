import Foundation
import AVFoundation
import Combine
import UIKit

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
    private let maxHistoryCount = 10  // 이동 평균용
    
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
            }
        }
    }
    
    // MARK: - Setup
    private func setupCaptureSession() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            
            let session = AVCaptureSession()
            session.sessionPreset = .low  // 조도만 필요하므로 최저 해상도
            
            // 후면 카메라 사용 (조도 측정에 더 정확)
            guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
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
    
    /// 이동평균으로 안정적인 Lux 값 계산
    private func smoothedLux(_ newLux: Double) -> Double {
        luxHistory.append(newLux)
        if luxHistory.count > maxHistoryCount {
            luxHistory.removeFirst()
        }
        return luxHistory.reduce(0, +) / Double(luxHistory.count)
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
extension LuxSensor: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        // 프레임마다 계산하면 과도하므로 5프레임에 1번만
        // (실제로는 output의 프레임레이트를 낮추는 것도 가능)
        guard let rawLux = calculateLux(from: sampleBuffer) else { return }
        
        let lux = smoothedLux(rawLux)
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.currentLux = lux
            self.lightLevel = self.classifyLightLevel(lux)
            self.isSunlight = lux >= self.outdoorThresholdLux
        }
    }
}

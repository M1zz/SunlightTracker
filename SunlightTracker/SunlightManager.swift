import Foundation
import SwiftUI
import CoreLocation
import Combine

@MainActor
class SunlightManager: NSObject, ObservableObject {
    
    // MARK: - Published
    @Published var todayRecord: SunlightRecord
    @Published var weeklyRecords: [SunlightRecord] = []
    @Published var isTracking = false           // 트래킹 활성화 여부 (센서 or 확인 후)
    @Published var isSunlightDetected = false   // 현재 햇빛 감지 중
    @Published var isConfirmedOutdoor = false   // 햇빛 확인 완료, 센서 꺼짐, 타이머 트래킹 중
    @Published var confirmedElapsedMinutes: Int = 0  // 확인 후 경과 시간 (분)
    @Published var lastKnownLux: Double = 0         // 확인 시점 조도 (게이지 표시용)
    @Published var currentSession: SunlightSession?
    @Published var sunTimes: SunTimes?
    @Published var settings: AppSettings
    @Published var streakCount: Int = 0
    @Published var locationAuthorized = false
    
    // Lux Sensor
    let luxSensor = LuxSensor()
    
    // MARK: - Private
    private let locationManager = CLLocationManager()
    private var samplingTimer: Timer?
    private var autoTrackTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    private let userDefaults = UserDefaults.standard
    private let recordsKey = "sunlight_records_v2"
    private let settingsKey = "app_settings_v2"
    
    // 자동 트래킹 상태
    private var sunlightStartTime: Date?       // 햇빛 감지 시작 시간
    private var consecutiveSunlightCount = 0   // 연속 햇빛 감지 횟수
    private var consecutiveDarkCount = 0       // 연속 어둠 감지 횟수
    private let activationThreshold = 3        // 3회 연속 감지 시 세션 시작 (~30초)
    private let deactivationThreshold = 6      // 6회 연속 미감지 시 세션 종료
    private var elapsedTimer: Timer?           // 확인 후 경과 시간 타이머
    
    // MARK: - Init
    override init() {
        let loadedSettings: AppSettings
        if let data = UserDefaults.standard.data(forKey: "app_settings_v2"),
           let saved = try? JSONDecoder().decode(AppSettings.self, from: data) {
            loadedSettings = saved
        } else {
            loadedSettings = .default
        }

        self.settings = loadedSettings
        self.todayRecord = SunlightRecord(goalMinutes: loadedSettings.dailyGoalMinutes)
        
        super.init()
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        
        loadRecords()
        loadTodayRecord()
        calculateStreak()
        calculateSunTimes()
        setupLuxObserving()
    }
    
    // MARK: - Lux Sensor Observation
    private func setupLuxObserving() {
        // 조도 센서의 isSunlight 변화를 관찰
        luxSensor.$currentLux
            .receive(on: DispatchQueue.main)
            .sink { [weak self] lux in
                self?.handleLuxUpdate(lux)
            }
            .store(in: &cancellables)
    }
    
    /// 조도 업데이트 처리 - 햇빛 감지 후 확인
    private func handleLuxUpdate(_ lux: Double) {
        guard isTracking, !isConfirmedOutdoor else { return }

        let isBright = lux >= settings.outdoorThresholdLux

        if isBright {
            consecutiveSunlightCount += 1
            consecutiveDarkCount = 0

            // 연속 밝음 감지 (~30초) → 햇빛 확인, 센서 끄고 타이머 전환
            if consecutiveSunlightCount >= activationThreshold && currentSession == nil {
                confirmAndStartTracking(initialLux: lux)
            }

            // 확인 전 세션 샘플 추가
            if var session = currentSession {
                session.luxSamples.append(lux)
                session.peakLux = max(session.peakLux, lux)
                currentSession = session
            }
        } else {
            consecutiveDarkCount += 1
            consecutiveSunlightCount = 0
        }

        // 조도 기록 저장
        let reading = LuxReading(lux: lux, lightLevel: luxSensor.lightLevel.rawValue)
        todayRecord.luxReadings.append(reading)

        if lux > todayRecord.peakLux {
            todayRecord.peakLux = lux
        }
    }

    // MARK: - Session Management

    /// 햇빛 확인 완료 → 센서 끄고 타이머 기반 트래킹 시작
    private func confirmAndStartTracking(initialLux: Double) {
        let session = SunlightSession(
            averageLux: initialLux,
            peakLux: initialLux,
            luxSamples: [initialLux],
            autoDetected: true
        )
        currentSession = session
        sunlightStartTime = Date()
        isSunlightDetected = true
        isConfirmedOutdoor = true
        lastKnownLux = initialLux

        // 센서 끄기 (배터리 절약)
        luxSensor.stopSensing()

        // 경과 시간 타이머 시작 (30초마다 업데이트)
        confirmedElapsedMinutes = 0
        elapsedTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self, let session = self.currentSession else { return }
                self.confirmedElapsedMinutes = max(Int(Date().timeIntervalSince(session.startTime) / 60), 0)
            }
        }
    }
    
    private func endSunlightSession() {
        guard var session = currentSession else { return }
        session.endTime = Date()
        
        // 평균 조도 계산
        if !session.luxSamples.isEmpty {
            session.averageLux = session.luxSamples.reduce(0, +) / Double(session.luxSamples.count)
        }
        
        let duration = session.durationMinutes
        if duration >= 1 { // 최소 1분 이상인 세션만 기록
            todayRecord.totalMinutes += duration
            todayRecord.sessions.append(session)
            
            // 전체 평균 조도 업데이트
            let allSamples = todayRecord.sessions.flatMap(\.luxSamples)
            if !allSamples.isEmpty {
                todayRecord.averageLux = allSamples.reduce(0, +) / Double(allSamples.count)
            }
            
            saveRecords()
            calculateStreak()
        }
        
        currentSession = nil
        isSunlightDetected = false
        sunlightStartTime = nil
    }
    
    // MARK: - Tracking Control

    /// 센서 활성화 (조도 측정 시작) - 앱 시작 시 자동 호출
    func startTracking() {
        guard !isTracking else { return }
        isTracking = true
        isConfirmedOutdoor = false
        confirmedElapsedMinutes = 0
        consecutiveSunlightCount = 0
        consecutiveDarkCount = 0
        luxSensor.sunlightThresholdLux = settings.sunlightThresholdLux
        luxSensor.outdoorThresholdLux = settings.outdoorThresholdLux
        luxSensor.startSensing()
    }

    /// 센서 감지 단계 취소 (아직 확인 전)
    func cancelDetecting() {
        guard isTracking, !isConfirmedOutdoor else { return }
        luxSensor.stopSensing()
        isTracking = false
        isSunlightDetected = false
        consecutiveSunlightCount = 0
        consecutiveDarkCount = 0
    }

    /// 사용자가 트래킹 종료 (확인 후 수동 종료)
    func finishTracking() {
        guard isConfirmedOutdoor else {
            // 감지 단계에서 종료 시
            stopTracking()
            return
        }

        // 경과 타이머 정리
        elapsedTimer?.invalidate()
        elapsedTimer = nil

        // 세션 종료 및 저장
        endSunlightSession()

        // 상태 초기화
        isTracking = false
        isConfirmedOutdoor = false
        isSunlightDetected = false
        confirmedElapsedMinutes = 0
        consecutiveSunlightCount = 0
        consecutiveDarkCount = 0
    }

    /// 내부 센서 비활성화 (레거시 호환)
    func stopTracking() {
        guard isTracking else { return }

        elapsedTimer?.invalidate()
        elapsedTimer = nil

        if currentSession != nil {
            endSunlightSession()
        }

        luxSensor.stopSensing()
        isTracking = false
        isConfirmedOutdoor = false
        isSunlightDetected = false
        confirmedElapsedMinutes = 0
        consecutiveSunlightCount = 0
        consecutiveDarkCount = 0
    }

    /// 트래킹 상태
    var trackingPhase: TrackingPhase {
        if isConfirmedOutdoor { return .confirmed }
        if isTracking { return .detecting }
        return .idle
    }

    enum TrackingPhase {
        case idle       // 대기 중
        case detecting  // 센서 감지 중
        case confirmed  // 햇빛 확인, 타이머 트래킹 중
    }
    
    /// 수동 세션 추가 (실외에서 카메라 없이 기록할 때)
    func addManualSession(minutes: Int, estimatedLux: Double = 5000) {
        let session = SunlightSession(
            startTime: Date().addingTimeInterval(-Double(minutes) * 60),
            endTime: Date(),
            averageLux: estimatedLux,
            peakLux: estimatedLux,
            luxSamples: [estimatedLux],
            autoDetected: false
        )
        
        todayRecord.totalMinutes += minutes
        todayRecord.sessions.append(session)
        if estimatedLux > todayRecord.peakLux {
            todayRecord.peakLux = estimatedLux
        }
        
        saveRecords()
        calculateStreak()
    }
    
    // MARK: - Location
    func requestLocation() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    func calculateSunTimes() {
        guard let location = locationManager.location else {
            calculateSunTimesForCoordinate(latitude: 37.5665, longitude: 126.9780)
            return
        }
        calculateSunTimesForCoordinate(
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude
        )
    }
    
    private func calculateSunTimesForCoordinate(latitude: Double, longitude: Double) {
        let now = Date()
        let calendar = Calendar.current
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: now) ?? 1
        
        let latRad = latitude * .pi / 180
        let declination = 23.45 * sin(2 * .pi * (284 + Double(dayOfYear)) / 365) * .pi / 180
        let hourAngle = acos(-tan(latRad) * tan(declination)) * 180 / .pi
        let solarNoon = 12.0 - longitude / 15.0 + Double(TimeZone.current.secondsFromGMT()) / 3600.0
        
        let sunriseHour = solarNoon - hourAngle / 15.0
        let sunsetHour = solarNoon + hourAngle / 15.0
        
        let startOfDay = calendar.startOfDay(for: now)
        let sunrise = startOfDay.addingTimeInterval(sunriseHour * 3600)
        let sunset = startOfDay.addingTimeInterval(sunsetHour * 3600)
        
        self.sunTimes = SunTimes(sunrise: sunrise, sunset: sunset)
    }
    
    // MARK: - Health Advice System
    let healthAdvices: [SunlightHealthAdvice] = [
        SunlightHealthAdvice(
            minuteThreshold: 10,
            title: "체내 시계 동기화 시작",
            description: "10분의 자연광으로 체내 시계가 동기화되기 시작하고, 피부에서 비타민D 생성이 시작됩니다.",
            icon: "clock.arrow.circlepath",
            category: .vitamin
        ),
        SunlightHealthAdvice(
            minuteThreshold: 15,
            title: "세로토닌 분비 활성화",
            description: "15분의 햇빛 노출로 세로토닌 수치가 상승하여 기분이 개선되기 시작합니다.",
            icon: "brain.head.profile",
            category: .mood
        ),
        SunlightHealthAdvice(
            minuteThreshold: 20,
            title: "기분 개선 효과 측정 가능",
            description: "20분 이상의 햇빛 노출 시 임상적으로 측정 가능한 수준의 기분 개선이 나타납니다.",
            icon: "face.smiling",
            category: .mood
        ),
        SunlightHealthAdvice(
            minuteThreshold: 30,
            title: "수면 질 향상 & 스트레스 감소",
            description: "30분의 자연광은 수면 시간을 23분 앞당기고, 코르티솔 수치를 25% 감소시킵니다. 계절성 우울증(SAD) 치료 표준량입니다.",
            icon: "moon.zzz",
            category: .sleep
        ),
        SunlightHealthAdvice(
            minuteThreshold: 45,
            title: "우울증 치료 최적 효과",
            description: "45분의 햇빛 노출은 우울증 치료에 최적의 효과를 보입니다. 20분 대비 현저한 증상 개선이 관찰됩니다.",
            icon: "heart.fill",
            category: .health
        ),
        SunlightHealthAdvice(
            minuteThreshold: 60,
            title: "수면 & 혈압 대폭 개선",
            description: "60분의 자연광 노출은 불면증 환자의 수면시간을 51분 증가시키고, 혈압을 11% 감소시킵니다.",
            icon: "bed.double.fill",
            category: .sleep
        )
    ]

    func currentAdvice(for minutes: Int) -> SunlightHealthAdvice? {
        healthAdvices.last(where: { $0.minuteThreshold <= minutes })
    }

    func nextMilestoneAdvice(for minutes: Int) -> (advice: SunlightHealthAdvice, remainingMinutes: Int)? {
        guard let next = healthAdvices.first(where: { $0.minuteThreshold > minutes }) else { return nil }
        return (next, next.minuteThreshold - minutes)
    }

    var motivationalMessage: String {
        let minutes = todayRecord.totalMinutes
        if minutes == 0 {
            return "오늘의 해바라기에게 햇빛을 선물해주세요"
        }
        if let next = nextMilestoneAdvice(for: minutes) {
            switch next.advice.category {
            case .sleep:
                return "\(next.remainingMinutes)분만 더 쐬면 수면이 좋아질 수 있어요!"
            case .mood:
                return "\(next.remainingMinutes)분 후면 세로토닌이 분비돼요!"
            case .stress:
                return "\(next.remainingMinutes)분만 더! 스트레스가 줄어들어요"
            case .health:
                return "\(next.remainingMinutes)분 더 나가면 건강에 큰 도움이 돼요"
            case .vitamin:
                return "\(next.remainingMinutes)분만 더 쐬면 비타민D가 생성돼요!"
            }
        }
        if todayRecord.goalAchieved {
            return "해바라기가 활짝 피었어요! 오늘도 건강한 하루!"
        }
        return "잘 하고 있어요! 해바라기가 자라고 있어요"
    }

    // MARK: - Persistence
    private func loadRecords() {
        guard let data = userDefaults.data(forKey: recordsKey),
              let records = try? JSONDecoder().decode([SunlightRecord].self, from: data) else {
            weeklyRecords = []
            return
        }
        weeklyRecords = records
    }
    
    private func loadTodayRecord() {
        if let existing = weeklyRecords.first(where: { Calendar.current.isDate($0.date, inSameDayAs: Date()) }) {
            todayRecord = existing
        } else {
            todayRecord = SunlightRecord(goalMinutes: settings.dailyGoalMinutes)
        }
    }
    
    func saveRecords() {
        if let index = weeklyRecords.firstIndex(where: { Calendar.current.isDate($0.date, inSameDayAs: Date()) }) {
            weeklyRecords[index] = todayRecord
        } else {
            weeklyRecords.append(todayRecord)
        }
        
        let cutoff = Calendar.current.date(byAdding: .day, value: -90, to: Date()) ?? Date()
        weeklyRecords = weeklyRecords.filter { $0.date > cutoff }
        
        if let data = try? JSONEncoder().encode(weeklyRecords) {
            userDefaults.set(data, forKey: recordsKey)
        }
    }
    
    func saveSettings() {
        if let data = try? JSONEncoder().encode(settings) {
            userDefaults.set(data, forKey: settingsKey)
        }
        todayRecord.goalMinutes = settings.dailyGoalMinutes
        luxSensor.sunlightThresholdLux = settings.sunlightThresholdLux
        luxSensor.outdoorThresholdLux = settings.outdoorThresholdLux
        saveRecords()
    }
    
    // MARK: - Stats
    func calculateStreak() {
        var streak = 0
        let calendar = Calendar.current
        var checkDate = Date()
        
        if !todayRecord.goalAchieved {
            checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate) ?? checkDate
        }
        
        for i in 0..<90 {
            let date = calendar.date(byAdding: .day, value: -i, to: checkDate) ?? checkDate
            if let record = weeklyRecords.first(where: { calendar.isDate($0.date, inSameDayAs: date) }),
               record.goalAchieved {
                streak += 1
            } else if i > 0 {
                break
            }
        }
        streakCount = streak
    }
    
    func getWeeklySummary() -> WeeklySummary {
        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let thisWeek = weeklyRecords.filter { $0.date >= weekAgo }
        return WeeklySummary(weekStart: weekAgo, records: thisWeek)
    }
    
    func getLast7DaysData() -> [(String, Int, Double)] {
        let calendar = Calendar.current
        var data: [(String, Int, Double)] = []
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "E"
        
        for i in (0..<7).reversed() {
            let date = calendar.date(byAdding: .day, value: -i, to: Date()) ?? Date()
            let dayStr = formatter.string(from: date)
            let record = weeklyRecords.first(where: { calendar.isDate($0.date, inSameDayAs: date) })
            let minutes = record?.totalMinutes ?? 0
            let avgLux = record?.averageLux ?? 0
            data.append((dayStr, minutes, avgLux))
        }
        return data
    }
    
}

// MARK: - CLLocationManagerDelegate
extension SunlightManager: CLLocationManagerDelegate {
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            switch manager.authorizationStatus {
            case .authorizedWhenInUse, .authorizedAlways:
                locationAuthorized = true
                manager.requestLocation()
            default:
                locationAuthorized = false
            }
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        Task { @MainActor in
            calculateSunTimes()
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            calculateSunTimesForCoordinate(latitude: 37.5665, longitude: 126.9780)
        }
    }
}

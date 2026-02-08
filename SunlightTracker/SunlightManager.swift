import Foundation
import SwiftUI
import CoreLocation
import Combine

@MainActor
class SunlightManager: NSObject, ObservableObject {
    
    // MARK: - Published
    @Published var todayRecord: SunlightRecord
    @Published var weeklyRecords: [SunlightRecord] = []
    @Published var isTracking = false           // 센서 활성화 여부
    @Published var isSunlightDetected = false   // 현재 햇빛 감지 중
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
    private let activationThreshold = 3        // 3회 연속 감지 시 세션 시작
    private let deactivationThreshold = 6      // 6회 연속 미감지 시 세션 종료
    
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
    
    /// 조도 업데이트 처리 - 자동 트래킹 로직
    private func handleLuxUpdate(_ lux: Double) {
        guard isTracking else { return }
        
        let isBright = lux >= settings.outdoorThresholdLux
        
        if isBright {
            consecutiveSunlightCount += 1
            consecutiveDarkCount = 0
            
            // 연속 밝음 감지 → 세션 시작
            if consecutiveSunlightCount >= activationThreshold && currentSession == nil {
                startSunlightSession()
            }
            
            // 진행 중인 세션에 샘플 추가
            if var session = currentSession {
                session.luxSamples.append(lux)
                session.peakLux = max(session.peakLux, lux)
                currentSession = session
            }
        } else {
            consecutiveDarkCount += 1
            consecutiveSunlightCount = 0
            
            // 연속 어둠 감지 → 세션 종료
            if consecutiveDarkCount >= deactivationThreshold && currentSession != nil {
                endSunlightSession()
            }
        }
        
        isSunlightDetected = (currentSession != nil)
        
        // 조도 기록 저장 (10초 간격)
        let reading = LuxReading(lux: lux, lightLevel: luxSensor.lightLevel.rawValue)
        todayRecord.luxReadings.append(reading)
        
        // 최고 조도 업데이트
        if lux > todayRecord.peakLux {
            todayRecord.peakLux = lux
        }
    }
    
    // MARK: - Session Management
    private func startSunlightSession() {
        let session = SunlightSession(autoDetected: settings.autoTrackingEnabled)
        currentSession = session
        sunlightStartTime = Date()
        isSunlightDetected = true
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
    
    /// 센서 활성화 (조도 측정 시작)
    func startTracking() {
        guard !isTracking else { return }
        isTracking = true
        consecutiveSunlightCount = 0
        consecutiveDarkCount = 0
        luxSensor.sunlightThresholdLux = settings.sunlightThresholdLux
        luxSensor.outdoorThresholdLux = settings.outdoorThresholdLux
        luxSensor.startSensing()
    }
    
    /// 센서 비활성화
    func stopTracking() {
        guard isTracking else { return }
        
        // 진행 중인 세션 종료
        if currentSession != nil {
            endSunlightSession()
        }
        
        luxSensor.stopSensing()
        isTracking = false
        isSunlightDetected = false
        consecutiveSunlightCount = 0
        consecutiveDarkCount = 0
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
    
    // MARK: - Persistence
    private func loadRecords() {
        guard let data = userDefaults.data(forKey: recordsKey),
              let records = try? JSONDecoder().decode([SunlightRecord].self, from: data) else {
            weeklyRecords = generateSampleData()
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
    
    // MARK: - Sample Data
    private func generateSampleData() -> [SunlightRecord] {
        let calendar = Calendar.current
        var records: [SunlightRecord] = []
        
        for i in 1..<7 {
            let date = calendar.date(byAdding: .day, value: -i, to: Date()) ?? Date()
            let minutes = Int.random(in: 10...60)
            let peakLux = Double.random(in: 2000...30000)
            let avgLux = peakLux * Double.random(in: 0.3...0.7)
            let record = SunlightRecord(
                date: date,
                totalMinutes: minutes,
                goalMinutes: settings.dailyGoalMinutes,
                peakLux: peakLux,
                averageLux: avgLux
            )
            records.append(record)
        }
        return records
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

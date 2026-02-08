import Foundation

// MARK: - 일조량 기록 모델
struct SunlightRecord: Identifiable, Codable {
    let id: UUID
    let date: Date
    var totalMinutes: Int
    var goalMinutes: Int
    var sessions: [SunlightSession]
    var luxReadings: [LuxReading]
    var peakLux: Double
    var averageLux: Double
    
    var goalProgress: Double {
        guard goalMinutes > 0 else { return 0 }
        return min(Double(totalMinutes) / Double(goalMinutes), 1.0)
    }
    
    var goalAchieved: Bool {
        totalMinutes >= goalMinutes
    }
    
    init(id: UUID = UUID(), date: Date = Date(), totalMinutes: Int = 0,
         goalMinutes: Int = 30, sessions: [SunlightSession] = [],
         luxReadings: [LuxReading] = [], peakLux: Double = 0, averageLux: Double = 0) {
        self.id = id
        self.date = date
        self.totalMinutes = totalMinutes
        self.goalMinutes = goalMinutes
        self.sessions = sessions
        self.luxReadings = luxReadings
        self.peakLux = peakLux
        self.averageLux = averageLux
    }
}

// MARK: - 조도 측정값
struct LuxReading: Identifiable, Codable {
    let id: UUID
    let timestamp: Date
    let lux: Double
    let lightLevel: String
    
    init(id: UUID = UUID(), timestamp: Date = Date(), lux: Double, lightLevel: String) {
        self.id = id
        self.timestamp = timestamp
        self.lux = lux
        self.lightLevel = lightLevel
    }
}

// MARK: - 개별 세션 (조도 기반)
struct SunlightSession: Identifiable, Codable {
    let id: UUID
    let startTime: Date
    var endTime: Date?
    var averageLux: Double
    var peakLux: Double
    var luxSamples: [Double]
    var autoDetected: Bool
    
    var durationMinutes: Int {
        guard let end = endTime else {
            return Int(Date().timeIntervalSince(startTime) / 60)
        }
        return Int(end.timeIntervalSince(startTime) / 60)
    }
    
    var luxDescription: String {
        if averageLux >= 10000 { return "강한 햇빛" }
        if averageLux >= 1000 { return "햇빛" }
        if averageLux >= 300 { return "실외/흐림" }
        return "약한 빛"
    }
    
    init(id: UUID = UUID(), startTime: Date = Date(), endTime: Date? = nil,
         averageLux: Double = 0, peakLux: Double = 0, luxSamples: [Double] = [],
         autoDetected: Bool = true) {
        self.id = id
        self.startTime = startTime
        self.endTime = endTime
        self.averageLux = averageLux
        self.peakLux = peakLux
        self.luxSamples = luxSamples
        self.autoDetected = autoDetected
    }
}

// MARK: - 주간 요약
struct WeeklySummary {
    let weekStart: Date
    let records: [SunlightRecord]
    
    var totalMinutes: Int {
        records.reduce(0) { $0 + $1.totalMinutes }
    }
    
    var averageMinutes: Double {
        guard !records.isEmpty else { return 0 }
        return Double(totalMinutes) / Double(records.count)
    }
    
    var goalAchievedDays: Int {
        records.filter { $0.goalAchieved }.count
    }
    
    var averagePeakLux: Double {
        let peaks = records.map(\.peakLux).filter { $0 > 0 }
        guard !peaks.isEmpty else { return 0 }
        return peaks.reduce(0, +) / Double(peaks.count)
    }
}

// MARK: - 일출/일몰 정보
struct SunTimes {
    let sunrise: Date
    let sunset: Date
    
    var daylightHours: Double {
        sunset.timeIntervalSince(sunrise) / 3600
    }
    
    var daylightDescription: String {
        let hours = Int(daylightHours)
        let minutes = Int((daylightHours - Double(hours)) * 60)
        return "\(hours)시간 \(minutes)분"
    }
}

// MARK: - 앱 설정
struct AppSettings: Codable {
    var dailyGoalMinutes: Int
    var reminderEnabled: Bool
    var reminderTime: Date
    var notifyGoalAchieved: Bool
    var notifyHalfway: Bool
    var autoTrackingEnabled: Bool
    var sunlightThresholdLux: Double
    var outdoorThresholdLux: Double
    var samplingIntervalSeconds: Int
    
    static let `default` = AppSettings(
        dailyGoalMinutes: 30,
        reminderEnabled: true,
        reminderTime: Calendar.current.date(from: DateComponents(hour: 10, minute: 0)) ?? Date(),
        notifyGoalAchieved: true,
        notifyHalfway: false,
        autoTrackingEnabled: true,
        sunlightThresholdLux: 1000,
        outdoorThresholdLux: 300,
        samplingIntervalSeconds: 10
    )
}

// MARK: - 건강 조언 모델
struct SunlightHealthAdvice {
    let minuteThreshold: Int
    let title: String
    let description: String
    let icon: String
    let category: Category

    enum Category: String {
        case sleep = "수면"
        case mood = "기분"
        case stress = "스트레스"
        case health = "건강"
        case vitamin = "비타민D"
    }
}

// MARK: - Extensions
extension Date {
    var startOfDay: Date { Calendar.current.startOfDay(for: self) }
    var isToday: Bool { Calendar.current.isDateInToday(self) }
    
    var shortDateString: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ko_KR")
        f.dateFormat = "M/d (E)"
        return f.string(from: self)
    }
    
    var timeString: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ko_KR")
        f.dateFormat = "a h:mm"
        return f.string(from: self)
    }
    
    var shortTimeString: String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f.string(from: self)
    }
}

extension Double {
    var luxFormatted: String {
        if self >= 10000 {
            return String(format: "%.0fk", self / 1000)
        } else if self >= 1000 {
            return String(format: "%.1fk", self / 1000)
        } else {
            return String(format: "%.0f", self)
        }
    }
}

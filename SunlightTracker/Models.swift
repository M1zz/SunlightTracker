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
    var mood: DailyMood?        // 오늘의 기분
    var note: String?           // 한마디 메모

    var goalProgress: Double {
        guard goalMinutes > 0 else { return 0 }
        return min(Double(totalMinutes) / Double(goalMinutes), 1.0)
    }

    var goalAchieved: Bool {
        totalMinutes >= goalMinutes
    }

    init(id: UUID = UUID(), date: Date = Date(), totalMinutes: Int = 0,
         goalMinutes: Int = 30, sessions: [SunlightSession] = [],
         luxReadings: [LuxReading] = [], peakLux: Double = 0, averageLux: Double = 0,
         mood: DailyMood? = nil, note: String? = nil) {
        self.id = id
        self.date = date
        self.totalMinutes = totalMinutes
        self.goalMinutes = goalMinutes
        self.sessions = sessions
        self.luxReadings = luxReadings
        self.peakLux = peakLux
        self.averageLux = averageLux
        self.mood = mood
        self.note = note
    }
}

// MARK: - 기분 이모지
enum DailyMood: String, Codable, CaseIterable {
    case veryHappy = "😄"
    case happy = "🙂"
    case neutral = "😐"
    case sad = "😔"
    case verySad = "😢"

    var description: String {
        switch self {
        case .veryHappy: return "매우 좋음"
        case .happy: return "좋음"
        case .neutral: return "보통"
        case .sad: return "안 좋음"
        case .verySad: return "매우 안 좋음"
        }
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
    var batteryEarned: Double  // 이 세션에서 획득한 배터리량

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
         autoDetected: Bool = true, batteryEarned: Double = 0) {
        self.id = id
        self.startTime = startTime
        self.endTime = endTime
        self.averageLux = averageLux
        self.peakLux = peakLux
        self.luxSamples = luxSamples
        self.autoDetected = autoDetected
        self.batteryEarned = batteryEarned
    }
}

// MARK: - 배터리 상태
struct BatteryStatus: Codable {
    var chargedAmount: Double  // 충전된 배터리량 (0~100%)
    var lastChargeTime: Date   // 마지막 충전 시간

    init(chargedAmount: Double = 0, lastChargeTime: Date = Date()) {
        self.chargedAmount = chargedAmount
        self.lastChargeTime = lastChargeTime
    }
}

// MARK: - 해바라기 건강 상태
struct SunflowerHealth: Codable {
    var currentEnergy: Double   // 현재 에너지 (0~100%)
    var lastUpdateTime: Date    // 마지막 업데이트 시간
    var decayRatePerHour: Double // 시간당 감소율 (기본 10%)

    var healthState: HealthState {
        if currentEnergy >= 80 { return .thriving }      // 싱싱
        if currentEnergy >= 50 { return .healthy }       // 건강
        if currentEnergy >= 20 { return .wilting }       // 시들어감
        return .critical                                  // 위험
    }

    enum HealthState: String {
        case thriving = "싱싱함"
        case healthy = "건강함"
        case wilting = "시들어감"
        case critical = "위험"
    }

    init(currentEnergy: Double = 100, lastUpdateTime: Date = Date(), decayRatePerHour: Double = 2.5) {
        self.currentEnergy = currentEnergy
        self.lastUpdateTime = lastUpdateTime
        self.decayRatePerHour = decayRatePerHour
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

// MARK: - 랜덤 건강 팁
struct HealthTip: Identifiable {
    let id = UUID()
    let category: TipCategory
    let title: String
    let description: String
    let icon: String
    let color: String // hex color

    enum TipCategory: String {
        case mental = "정신건강"
        case physical = "육체건강"
        case vitamin = "비타민D"
        case sleep = "수면"
        case immune = "면역력"
    }

    static let allTips: [HealthTip] = [
        // 정신건강
        HealthTip(category: .mental, title: "우울증 예방", description: "햇빛은 세로토닌 분비를 촉진하여 우울증 증상을 완화합니다. 매일 30분 이상의 햇빛 노출은 계절성 우울증(SAD) 치료에 효과적입니다.", icon: "brain.head.profile", color: "#4A90E2"),
        HealthTip(category: .mental, title: "기분 개선", description: "자연광 노출은 기분을 조절하는 신경전달물질을 활성화합니다. 15-20분의 햇빛만으로도 긍정적인 감정 변화를 경험할 수 있습니다.", icon: "face.smiling", color: "#F5A623"),
        HealthTip(category: .mental, title: "스트레스 감소", description: "햇빛은 코르티솔(스트레스 호르몬) 수치를 25% 낮춰줍니다. 점심시간 햇빛 산책은 오후 업무 스트레스를 줄이는데 도움이 됩니다.", icon: "heart.text.square", color: "#50E3C2"),
        HealthTip(category: .mental, title: "집중력 향상", description: "자연광은 인지 기능과 집중력을 향상시킵니다. 실내에서 일할 때도 창가 자리를 선택하면 업무 효율이 15% 증가합니다.", icon: "lightbulb.fill", color: "#FFD700"),

        // 육체건강
        HealthTip(category: .physical, title: "뼈 건강", description: "햇빛으로 생성되는 비타민D는 칼슘 흡수를 돕습니다. 주 3-4회, 팔다리를 노출한 채 15분 햇빛을 쬐면 충분한 비타민D를 얻을 수 있습니다.", icon: "figure.walk", color: "#8B572A"),
        HealthTip(category: .physical, title: "혈압 조절", description: "햇빛은 혈관을 확장시켜 혈압을 낮춰줍니다. 60분의 햇빛 노출은 수축기 혈압을 11% 감소시키는 효과가 있습니다.", icon: "heart.circle", color: "#E74C3C"),
        HealthTip(category: .physical, title: "근육 기능", description: "비타민D는 근육 기능과 회복에 필수적입니다. 운동 전후 햇빛 노출은 근육통을 줄이고 회복 속도를 높입니다.", icon: "figure.strengthtraining.traditional", color: "#9B59B6"),
        HealthTip(category: .physical, title: "피부 건강", description: "적절한 햇빛 노출은 여드름, 건선 등 피부 질환 개선에 도움이 됩니다. 단, 자외선 차단제 사용과 함께 적절한 시간(아침/저녁) 선택이 중요합니다.", icon: "sparkles", color: "#FF69B4"),

        // 비타민D
        HealthTip(category: .vitamin, title: "비타민D 합성", description: "피부가 UVB 광선에 노출되면 비타민D가 생성됩니다. 손, 팔, 다리를 노출한 상태로 15-30분이면 하루 필요량을 충족할 수 있습니다.", icon: "sun.max.fill", color: "#FDB813"),
        HealthTip(category: .vitamin, title: "면역력 강화", description: "비타민D는 면역세포를 활성화하여 감염 예방에 도움을 줍니다. 충분한 비타민D 수치는 감기와 독감 발생률을 40% 낮춥니다.", icon: "shield.fill", color: "#3498DB"),
        HealthTip(category: .vitamin, title: "만성질환 예방", description: "비타민D 결핍은 심혈관 질환, 당뇨병, 일부 암과 연관이 있습니다. 규칙적인 햇빛 노출로 만성질환 위험을 줄일 수 있습니다.", icon: "cross.case.fill", color: "#E67E22"),

        // 수면
        HealthTip(category: .sleep, title: "체내 시계 동기화", description: "아침 햇빛은 생체리듬을 조절하는 멜라토닌 분비를 억제합니다. 기상 후 10분 햇빛 노출로 밤에 더 잘 잘 수 있습니다.", icon: "moon.zzz", color: "#34495E"),
        HealthTip(category: .sleep, title: "수면 시간 증가", description: "30분의 자연광 노출은 수면 시작 시간을 23분 앞당깁니다. 불면증 환자는 60분 햇빛 노출로 수면시간이 51분 증가합니다.", icon: "bed.double.fill", color: "#5DADE2"),
        HealthTip(category: .sleep, title: "수면의 질 향상", description: "햇빛은 깊은 수면(REM 수면) 비율을 높여줍니다. 낮에 충분한 햇빛을 받으면 야간 수면의 질이 30% 향상됩니다.", icon: "powersleep", color: "#1ABC9C"),

        // 면역력
        HealthTip(category: .immune, title: "백혈구 활성화", description: "햇빛은 T세포와 같은 면역세포를 활성화합니다. 규칙적인 햇빛 노출로 면역 반응 속도가 빨라집니다.", icon: "drop.fill", color: "#C0392B"),
        HealthTip(category: .immune, title: "항염 효과", description: "햇빛은 염증성 사이토카인 수치를 낮춰 만성 염증을 줄입니다. 자가면역 질환 증상 완화에도 도움이 됩니다.", icon: "waveform.path.ecg", color: "#16A085"),
        HealthTip(category: .immune, title: "항산화 효과", description: "적절한 햇빛 노출은 체내 항산화 시스템을 강화합니다. 이는 세포 손상을 줄이고 노화를 늦추는데 기여합니다.", icon: "leaf.arrow.triangle.circlepath", color: "#27AE60")
    ]
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

// MARK: - Shared Data Manager
class SharedDataManager {
    static let shared = SharedDataManager()
    private let appGroupID = "group.com.leeo.sunflower"
    private let sharedDefaults: UserDefaults?
    private let widgetDataKey = "widget_data"

    init() {
        sharedDefaults = UserDefaults(suiteName: appGroupID)
    }

    func saveWidgetData(_ data: WidgetData) {
        guard let encoded = try? JSONEncoder().encode(data) else { return }
        sharedDefaults?.set(encoded, forKey: widgetDataKey)
    }

    func loadWidgetData() -> WidgetData? {
        guard let data = sharedDefaults?.data(forKey: widgetDataKey),
              let decoded = try? JSONDecoder().decode(WidgetData.self, from: data) else {
            return nil
        }
        return decoded
    }
}

// MARK: - Widget Data Model
struct WidgetData: Codable {
    let batteryPercentage: Double
    let lastChargeTime: Date
    let sunflowerEnergy: Double
    let healthState: String  // "thriving", "healthy", "wilting", "critical"
    let todayMinutes: Int
    let goalMinutes: Int
    let lastUpdate: Date

    // 트래킹 상태
    let isTracking: Bool
    let isConfirmedOutdoor: Bool
    let currentLux: Double
    let estimatedBatteryGain: Double
    let confirmedElapsedMinutes: Int

    var goalProgress: Double {
        guard goalMinutes > 0 else { return 0 }
        return min(Double(todayMinutes) / Double(goalMinutes), 1.0)
    }
}

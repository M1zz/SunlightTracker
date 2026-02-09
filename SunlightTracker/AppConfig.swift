import Foundation

/// 앱 설정 및 버전 관리
struct AppConfig {
    /// 앱 버전 (여기서만 수정하면 앱 전체에 반영됨)
    static let version = "1.0.0"

    /// 빌드 번호
    static let buildNumber = "1"

    /// 앱 이름
    static let appName = "햇빛바라기"

    /// 전체 버전 문자열
    static var fullVersion: String {
        "\(version) (\(buildNumber))"
    }

    // MARK: - 햇빛 노출 권장사항

    /// 하루 권장 햇빛 노출 시간 (분)
    static let recommendedDailyMinutes = 30

    /// 권장 세션 횟수 (하루)
    static let recommendedSessions = 2...3

    /// 최적 햇빛 시간대 (시작 시간)
    static let optimalStartHour = 10

    /// 최적 햇빛 시간대 (종료 시간)
    static let optimalEndHour = 15

    /// 자외선 차단제 없이 권장되는 최대 시간 (분)
    static let maxMinutesWithoutSunscreen = 30

    // MARK: - 기본 설정

    /// 기본 목표 시간 (분)
    static let defaultGoalMinutes = 30

    /// 기본 햇빛 임계값 (lux)
    static let defaultSunlightThreshold = 1000.0

    /// 기본 실외 임계값 (lux)
    static let defaultOutdoorThreshold = 300.0
}

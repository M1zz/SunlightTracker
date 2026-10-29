import Foundation
import LeeoKit

enum SunlightTrackerSpec: LeeoAppSpec {
    static let appName = "햇빛바라기"
    static let developerEmail = "leeo@kakao.com"
    /// 친구에게 소개하기·리뷰 남기기 링크에 쓴다.
    static let appStoreID: String? = "6758931631"
    static let feedback = LeeoFeedbackConfig(containerIdentifier: "iCloud.com.Ysoup.FeedbackHub", appIdentifier: "com.leeo.sunflower")

    /// 개인정보 처리방침·지원 페이지 (README 에 공개된 링크, docs/ 를 GitHub Pages 로 서빙).
    static let legal = LeeoLegalConfig(
        privacyURL: URL(string: "https://m1zz.github.io/SunlightTracker/privacy.html")!,
        supportURL: URL(string: "https://m1zz.github.io/SunlightTracker/support.html")!,
        marketingURL: URL(string: "https://m1zz.github.io/SunlightTracker/")!
    )

    /// 결제 없음 — 앱 안에 StoreKit·페이월 코드가 존재하지 않는다.
    static let monetization = LeeoMonetization.free

    /// 익명 사용 통계 → FeedbackHub. 없으면 bootstrap 이 스냅샷·app_open 을 건너뛴다.
    static let analytics: any LeeoAnalytics = LeeoUsageAnalytics(spec: SunlightTrackerSpec.self)
}

extension SunlightTrackerSpec {
    /// 무료 앱이라 LeeoStore 가 없다 — 팁만 혼자 받는다(앱을 열 때 `startStandalone()`, → SunlightTrackerApp).
    /// 소모성 상품 셋, 작은 것부터. ⚠️ 기능을 여는 상품이 아니다.
    @MainActor static let tipJar = LeeoTipJar(config: LeeoTipJarConfig(productIDs: [
        "com.leeo.sunflower.tip.small",
        "com.leeo.sunflower.tip.medium",
        "com.leeo.sunflower.tip.large",
    ]))
}

/// 팁을 부탁할 만한 순간 — 햇빛 목표를 채운 날 수. 기록은 최근 90일만 남으므로 그 안에서 센다.
enum SunlightTipMoments {
    /// 목표를 채운 날 수. 큰 것부터.
    static let goalDays = [60, 30, 10]

    /// 넘어선 순간, 인상적인 것부터.
    static func reached(goalDays days: Int) -> [LeeoTipMoment] {
        goalDays.filter { days >= $0 }.map { threshold in
            LeeoTipMoment(id: "goalDays.\(threshold)",
                          message: String(localized: "최근 석 달 동안 햇빛 목표를 \(days)일 채웠어요",
                                          comment: "Tip ask card: on how many days (within the last 90) the person met their daylight goal"))
        }
    }
}

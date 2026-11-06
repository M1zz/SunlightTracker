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

    /// **햇빛 모으기는 전부 무료, 앱을 열지 않아도 해바라기가 보이는 것은 Pro.**
    ///
    /// 무료 · Pro 두 칸. Pro 는 주 · 월 · 연 구독(한 구독 그룹)과 평생, 구독 졸업 평생.
    /// 무엇이 열리는지는 `ProGate`, 상품 ID 는 `ProProduct`, 열려 있는지는 `SunflowerPro.isOpen` 한 곳에 있다.
    /// 1.1.0(빌드 9)까지 받은 사람은 Pro 를 그대로 쓴다(`SunflowerPro.lastBuildBeforePaywall`).
    static let monetization = LeeoMonetization.freemiumSubscription(
        LeeoSubscriptionConfig(
            productIDs: ProProduct.all,
            // 자체 약관이 없으므로 애플 표준 사용권 계약(EULA)을 건다.
            termsURL: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!,
            gate: LeeoGatePolicy(proOnly: Set(ProGate.allCases.map(\.rawValue))),
            cacheSuiteName: "group.com.leeo.sunflower"))

    /// 백업 금고가 함께 떠 두는 공유 저장소 (위젯과 나누는 것).
    static let appGroups = ["group.com.leeo.sunflower"]

    /// 익명 사용 통계 → FeedbackHub. 없으면 bootstrap 이 스냅샷·app_open 을 건너뛴다.
    static let analytics: any LeeoAnalytics = LeeoUsageAnalytics(spec: SunlightTrackerSpec.self)
}

extension SunlightTrackerSpec {
    /// 팁은 Pro 와 따로 혼자 받는다(앱을 열 때 `startStandalone()`, → SunlightTrackerApp).
    /// 지금까지 센 팁이 이 기기의 기본 저장소에 있어서 그대로 둔다.
    /// 소모성 상품 셋, 작은 것부터. ⚠️ 기능을 여는 상품이 아니다 — `ProProduct` 에 넣지 않는다.
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

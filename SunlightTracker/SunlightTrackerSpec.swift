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

import SwiftUI
import LeeoKit

@main
struct SunlightTrackerApp: App {
    init() {
        // 실행 기록 + 익명 사용 통계·크래시 진단(FeedbackHub)을 한 번에 켠다.
        LeeoKit.bootstrap(SunlightTrackerSpec.self)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .leeoSatisfactionCheck(SunlightTrackerSpec.self)
                // 팁 상품을 불러오고 끝나지 않은 팁을 마저 센다 (무료 앱이라 LeeoStore 대신 혼자)
                .task { await SunlightTrackerSpec.tipJar.startStandalone() }
        }
    }
}

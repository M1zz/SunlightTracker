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
        }
    }
}

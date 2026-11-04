import SwiftUI
import LeeoKit

@main
struct SunlightTrackerApp: App {
    @Environment(\.scenePhase) private var scenePhase

    init() {
        // 실행 기록 + 익명 사용 통계·크래시 진단(FeedbackHub)을 한 번에 켠다.
        LeeoKit.bootstrap(SunlightTrackerSpec.self)
        // 건강 앱이 새 햇빛 기록으로 앱을 뒤에서 깨울 때도 받을 수 있게 화면보다 먼저 만든다.
        _ = SunlightManager.shared
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .leeoSatisfactionCheck(SunlightTrackerSpec.self)
                // 팁 상품을 불러오고 끝나지 않은 팁을 마저 센다 (무료 앱이라 LeeoStore 대신 혼자)
                .task { await SunlightTrackerSpec.tipJar.startStandalone() }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { Task { await SunlightManager.shared.syncDaylightFromHealth() } }
        }
    }
}

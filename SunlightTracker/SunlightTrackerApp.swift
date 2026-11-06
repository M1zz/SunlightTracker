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
                // 팁 상품을 불러오고 끝나지 않은 팁을 마저 센다 (팁은 Pro 의 LeeoStore 와 따로 혼자)
                .task { await SunlightTrackerSpec.tipJar.startStandalone() }
                .task { await SunflowerPro.shared.refresh() }
        }
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active else { return }
            Task { await SunlightManager.shared.syncDaylightFromHealth() }
            // 영수증 · 상품을 다시 읽고 위젯에 같은 답을 비춘다. 구독 졸업 때가 됐으면 여기서 뜬다.
            Task { await SunflowerPro.shared.refresh() }
        }
    }
}

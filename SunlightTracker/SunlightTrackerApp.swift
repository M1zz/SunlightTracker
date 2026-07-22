import SwiftUI
import LeeoKit

@main
struct SunlightTrackerApp: App {
    init() {
        LeeoEngagement.shared.registerLaunch()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .leeoSatisfactionCheck(SunlightTrackerSpec.self)
        }
    }
}

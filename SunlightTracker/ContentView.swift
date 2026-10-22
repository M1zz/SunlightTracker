import SwiftUI

struct ContentView: View {
    @StateObject private var manager = SunlightManager()
    @StateObject private var weatherService = WeatherService()
    @StateObject private var notificationManager = NotificationManager.shared
    /// 스토어 스크린샷용: Debug 빌드에서만 `-ScreenshotTab <번호>` 실행 인자로 처음 탭을 고른다.
    @State private var selectedTab: Int = {
        #if DEBUG
        return UserDefaults.standard.integer(forKey: "ScreenshotTab")
        #else
        return 0
        #endif
    }()

    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView(manager: manager, weatherService: weatherService)
                .tabItem {
                    Label("오늘", systemImage: "leaf.fill")
                }
                .tag(0)
            
            RecordsView(manager: manager)
                .tabItem {
                    Label(String(localized: "tab.records", defaultValue: "기록"), systemImage: "calendar")
                }
                .tag(1)

            FriendsView(manager: manager)
                .tabItem {
                    Label(String(localized: "tab.friends", defaultValue: "친구"), systemImage: "person.2.fill")
                }
                .tag(2)

            SettingsView(manager: manager, notificationManager: notificationManager)
                .tabItem {
                    Label("설정", systemImage: "gearshape.fill")
                }
                .tag(3)
        }
        .tint(.orange)
    }
}

#Preview {
    ContentView()
}

import SwiftUI

struct ContentView: View {
    @StateObject private var manager = SunlightManager()
    @StateObject private var weatherService = WeatherService()
    @StateObject private var notificationManager = NotificationManager.shared
    
    var body: some View {
        TabView {
            DashboardView(manager: manager, weatherService: weatherService)
                .tabItem {
                    Label("오늘", systemImage: "leaf.fill")
                }
            
            HistoryView(manager: manager)
                .tabItem {
                    Label("기록", systemImage: "chart.bar.fill")
                }
            
            SettingsView(manager: manager, notificationManager: notificationManager)
                .tabItem {
                    Label("설정", systemImage: "gearshape.fill")
                }
        }
        .tint(.orange)
    }
}

#Preview {
    ContentView()
}

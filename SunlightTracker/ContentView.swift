import SwiftUI
import LeeoKit

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

            // 아이폰 듀오를 펴면 왼쪽(세로면 아래)에 이 탭, 오른쪽(위)에 오늘 해바라기가 선다.
            // 접혀 있거나 보통 아이폰이면 `FoldTab` 은 이 탭만 그린다. 지금 화면 그대로다.
            FoldTab { RecordsView(manager: manager) } today: { todayPane }
                .tabItem {
                    Label(String(localized: "tab.records", defaultValue: "기록"), systemImage: "calendar")
                }
                .tag(1)

            FoldTab { FriendsView(manager: manager) } today: { todayPane }
                .tabItem {
                    Label(String(localized: "tab.friends", defaultValue: "친구"), systemImage: "person.2.fill")
                }
                .tag(2)

            FoldTab { SettingsView(manager: manager, notificationManager: notificationManager) } today: { todayPane }
                .tabItem {
                    Label("설정", systemImage: "gearshape.fill")
                }
                .tag(3)
        }
        .tint(.orange)
        // 펴면 시스템 탭바 대신 고르는 쪽 판 바닥에 막대가 선다. 오늘은 늘 오른쪽 판에 있어 막대에서 빠진다.
        .foldTabBar(items: foldTabItems, selected: selectedTab == 0 ? 1 : selectedTab) { selectedTab = $0 }
        .modifier(FoldTodayTabRedirect(selectedTab: $selectedTab))
        // 창 크기로 접힘을 재서 아래로 흘린다. 시트 · 알림창도 접힌 선을 비킨다 (LeeoKit Fold).
        .foldAware()
    }

    /// 펼친 화면의 결과 쪽: 오늘 탭 화면 그대로. 해바라기 · 오늘 받은 햇빛 · 배터리가 늘 보인다.
    private var todayPane: some View {
        DashboardView(manager: manager, weatherService: weatherService)
    }

    private var foldTabItems: [FoldTabBar<Int>.Item] {
        [
            .init(value: 1, title: String(localized: "tab.records", defaultValue: "기록"), symbol: "calendar"),
            .init(value: 2, title: String(localized: "tab.friends", defaultValue: "친구"), symbol: "person.2.fill"),
            .init(value: 3, title: String(localized: "설정"), symbol: "gearshape.fill"),
        ]
    }
}

// MARK: - 아이폰 듀오

/// 펼친 화면의 탭 한 장: 고르는 쪽(기록 · 친구 · 설정) | 결과 쪽(오늘).
private struct FoldTab<Choose: View, Today: View>: View {
    @ViewBuilder let choose: () -> Choose
    @ViewBuilder let today: () -> Today

    var body: some View {
        FoldSplitView {
            choose()
        } result: {
            // 결과 쪽 판 안에서는 접히지 않은 화면처럼 선다.
            today().environment(\.foldLayout, .single)
        }
        .foldTabBarRoom()
    }
}

/// 펼쳤을 때 오늘 탭에 있었다면 기록으로 옮긴다. 오늘은 그 오른쪽 판에 그대로 서 있다.
private struct FoldTodayTabRedirect: ViewModifier {
    @Environment(\.foldLayout) private var fold
    @Binding var selectedTab: Int

    func body(content: Content) -> some View {
        content.onChange(of: fold.isUnfolded, initial: true) { _, unfolded in
            if unfolded, selectedTab == 0 { selectedTab = 1 }
        }
    }
}

#Preview {
    ContentView()
}

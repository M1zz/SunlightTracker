//
//  WatchShared.swift
//  워치 앱 · 컴플리케이션이 함께 쓴다.
//

import SwiftUI

/// 워치 안 공유 저장소. 워치 앱이 쓰고 컴플리케이션이 읽는다.
enum WatchStore {
    private static let defaults = UserDefaults(suiteName: "group.com.leeo.sunflower") ?? .standard
    private static let snapshotKey = "watch_snapshot"
    private static let minutesKey = "watch_daylight_minutes"
    private static let minutesDayKey = "watch_daylight_day"

    /// 아이폰이 마지막으로 보내 준 해바라기 상태.
    static var snapshot: WatchSnapshot? {
        get { WatchSnapshot.decode(defaults.data(forKey: snapshotKey)) }
        set { defaults.set(newValue?.encoded, forKey: snapshotKey) }
    }

    /// 워치가 건강 앱에서 직접 읽은 오늘 햇빛(분).
    static func watchMinutes(on date: Date) -> Int {
        guard let day = defaults.object(forKey: minutesDayKey) as? Date,
              Calendar.current.isDate(day, inSameDayAs: date) else { return 0 }
        return defaults.integer(forKey: minutesKey)
    }

    static func setWatchMinutes(_ minutes: Int, at date: Date) {
        defaults.set(minutes, forKey: minutesKey)
        defaults.set(date, forKey: minutesDayKey)
    }

    /// 보여 줄 오늘 햇빛: 아이폰이 겹침 없이 센 값과 워치가 직접 읽은 값 중 큰 쪽.
    /// 폰이 멀리 있어도 늘어나고, 같은 시간을 두 번 더하지 않는다.
    static func todayMinutes(at date: Date) -> Int {
        max(snapshot?.minutes(on: date) ?? 0, watchMinutes(on: date))
    }

    static func goalMinutes() -> Int { snapshot?.goalMinutes ?? 30 }
}

/// 해바라기 기분 — 아이폰 앱과 같은 경계(80 · 50 · 20).
enum SunflowerMood {
    case thriving, healthy, wilting, critical

    init(energy: Double) {
        switch energy {
        case 80...: self = .thriving
        case 50...: self = .healthy
        case 20...: self = .wilting
        default: self = .critical
        }
    }

    var title: LocalizedStringKey {
        switch self {
        case .thriving: "싱싱함"
        case .healthy: "건강함"
        case .wilting: "시들어감"
        case .critical: "위험"
        }
    }

    var color: Color {
        switch self {
        case .thriving: .yellow
        case .healthy: .orange
        case .wilting: Color(red: 0.8, green: 0.6, blue: 0.3)
        case .critical: .red
        }
    }
}

/// 손목 크기의 해바라기. 에너지가 줄면 꽃잎이 짧아지고 빛이 바랜다.
struct SunflowerMark: View {
    var energy: Double

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let vigor = 0.6 + 0.4 * min(max(energy, 0), 100) / 100
            ZStack {
                ForEach(0..<12, id: \.self) { i in
                    Ellipse()
                        .fill(LinearGradient(colors: [.yellow, .orange], startPoint: .top, endPoint: .bottom))
                        .frame(width: size * 0.2, height: size * 0.36 * vigor)
                        .offset(y: -size * (0.2 + 0.14 * vigor))
                        .rotationEffect(.degrees(Double(i) * 30))
                }
                Circle()
                    .fill(Color(red: 0.45, green: 0.27, blue: 0.1))
                    .frame(width: size * 0.42, height: size * 0.42)
            }
            .saturation(0.35 + 0.65 * min(max(energy, 0), 100) / 100)
            .frame(width: size, height: size)
            .position(x: geo.size.width / 2, y: geo.size.height / 2)
        }
        .accessibilityHidden(true)
    }
}

//
//  widget.swift
//  widget
//
//  Created by Leeo on 2/9/26.
//

import WidgetKit
import SwiftUI

// MARK: - Timeline Provider
struct SunflowerWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> SunflowerEntry {
        SunflowerEntry.placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (SunflowerEntry) -> Void) {
        var entry = loadEntry()
        // 위젯 갤러리에서는 무엇이 생기는지 그대로 보인다. 홈 화면에 올린 뒤에 잠긴다.
        if context.isPreview { entry.isOpen = true }
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SunflowerEntry>) -> Void) {
        let currentEntry = loadEntry()
        let updateDate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
        let timeline = Timeline(entries: [currentEntry], policy: .after(updateDate))
        completion(timeline)
    }

    private func loadEntry() -> SunflowerEntry {
        guard let data = SharedDataManager.shared.loadWidgetData() else {
            return SunflowerEntry.placeholder
        }
        return SunflowerEntry(date: Date(), widgetData: data, isOpen: SharedDataManager.shared.widgetsOpen)
    }
}

// MARK: - Timeline Entry
struct SunflowerEntry: TimelineEntry {
    let date: Date
    let widgetData: WidgetData
    /// 홈 화면 위젯은 Pro. 앱이 App Group 에 적은 답을 따른다 (→ SunflowerPro).
    var isOpen: Bool = true

    static let placeholder = SunflowerEntry(
        date: Date(),
        widgetData: WidgetData(
            batteryPercentage: 45,
            lastChargeTime: Date().addingTimeInterval(-3600),
            sunflowerEnergy: 75,
            healthState: "healthy",
            todayMinutes: 15,
            goalMinutes: 30,
            lastUpdate: Date(),
            isTracking: false,
            isConfirmedOutdoor: false,
            currentLux: 0,
            estimatedBatteryGain: 0,
            confirmedElapsedMinutes: 0
        )
    )
}

// MARK: - 지금 남은 햇빛 배터리
extension WidgetData {
    /// 저장된 값은 마지막으로 잰 때의 것 — 위젯이 그려지는 시각까지 줄어든 만큼 뺀다. 밖에 있으면 받는 중인 몫을 더한다.
    func batteryLevel(at date: Date) -> Double {
        if isConfirmedOutdoor { return min(100, sunflowerEnergy + estimatedBatteryGain) }
        return SunBattery.level(sunflowerEnergy, at: lastUpdate, now: date)
    }
}

/// 해 위에 남은 %를 얹은 빛살 게이지
struct WidgetSunGauge: View {
    let level: Double
    var body: some View {
        SunRays(level: level) {
            GeometryReader { geo in
                Text(verbatim: "\(Int(level.rounded()))%")
                    .font(.system(size: geo.size.width * 0.30, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .minimumScaleFactor(0.5)
                    .foregroundStyle(SunPalette.ink)
                    .frame(width: geo.size.width, height: geo.size.height)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("햇빛 배터리"))
        .accessibilityValue(Text(verbatim: "\(Int(level.rounded()))%"))
    }
}

// MARK: - 햇빛 배터리 (Small)
struct SunflowerWidgetView: View {
    var entry: SunflowerEntry

    var body: some View {
        WidgetSunGauge(level: entry.widgetData.batteryLevel(at: entry.date))
            .padding(4)
            .containerBackground(SunPalette.sky, for: .widget)
    }
}

// MARK: - 오늘 진행도 위젯 (Small)
struct TodayProgressWidgetView: View {
    var entry: SunflowerEntry

    private var progress: Double { entry.widgetData.goalProgress }

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.3), lineWidth: 12)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(SunPalette.sun, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    // 시계처럼 위에서 시계 방향으로 찬다. 오른쪽에서 왼쪽으로 쓰는 언어(아랍어)에서도 같은 방향
                    .environment(\.layoutDirection, .leftToRight)
                Text("\(entry.widgetData.todayMinutes)분")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .minimumScaleFactor(0.6)
                    .foregroundStyle(.white)
            }
            .frame(width: 96, height: 96)

            Text("목표: \(entry.widgetData.goalMinutes)분")
                .font(.caption.bold())
                .foregroundStyle(.white.opacity(0.85))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .containerBackground(SunPalette.sky, for: .widget)
    }
}

// MARK: - 종합 정보 위젯 (Medium)
struct CompactInfoWidgetView: View {
    var entry: SunflowerEntry

    var body: some View {
        HStack(spacing: 20) {
            WidgetSunGauge(level: entry.widgetData.batteryLevel(at: entry.date))
            TodayMinutes(data: entry.widgetData)
        }
        .padding(.vertical, 4)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .containerBackground(SunPalette.sky, for: .widget)
    }
}

// MARK: - 대시보드 위젯 (Large)
struct DashboardWidgetView: View {
    var entry: SunflowerEntry

    var body: some View {
        VStack(spacing: 20) {
            WidgetSunGauge(level: entry.widgetData.batteryLevel(at: entry.date))
                .padding(.horizontal, 30)
            TodayMinutes(data: entry.widgetData)
        }
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .containerBackground(SunPalette.sky, for: .widget)
    }
}

/// 오늘 밖에서 받은 시간과 목표 막대
struct TodayMinutes: View {
    let data: WidgetData

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("오늘의 햇빛")
                .font(.caption.bold())
                .foregroundStyle(.white.opacity(0.85))
            Text("\(data.todayMinutes) / \(data.goalMinutes)분")
                .font(.system(.title2, design: .rounded).weight(.bold))
                .foregroundStyle(.white)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.3))
                    Capsule().fill(SunPalette.sun)
                        .frame(width: max(8, geo.size.width * data.goalProgress))
                }
            }
            .frame(height: 10)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Pro 잠금

/// 무료로 쓰는 사람이 올린 위젯: 흐린 게이지 위에 '탭해서 Pro 열기'. 누르면 앱에서 페이월이 뜬다.
struct ProLockedWidget<Content: View>: View {
    let isOpen: Bool
    @ViewBuilder let content: () -> Content

    var body: some View {
        if isOpen {
            content()
        } else {
            content()
                .blur(radius: 6)
                .opacity(0.4)
                .accessibilityHidden(true)
                .overlay {
                    VStack(spacing: 6) {
                        Image(systemName: "lock.fill")
                            .font(.title3)
                            .foregroundStyle(.white)
                            .accessibilityHidden(true)
                        Text("탭해서 Pro 열기")
                            .font(.body.weight(.semibold))
                            .multilineTextAlignment(.center)
                            .minimumScaleFactor(0.7)
                            .foregroundStyle(.white)
                    }
                    .padding(8)
                }
                .widgetURL(URL(string: "sunflower://pro/widget"))
        }
    }
}

// MARK: - 위젯 설정들

struct SunflowerWidget: Widget {
    let kind: String = "SunflowerWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SunflowerWidgetProvider()) { entry in
            ProLockedWidget(isOpen: entry.isOpen) { SunflowerWidgetView(entry: entry) }
                .appLocale()
        }
        .configurationDisplayName("햇빛 배터리")
        .description("남은 햇빛 배터리를 확인하세요")
        .supportedFamilies([.systemSmall])
    }
}

struct TodayProgressWidget: Widget {
    let kind: String = "TodayProgressWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SunflowerWidgetProvider()) { entry in
            ProLockedWidget(isOpen: entry.isOpen) { TodayProgressWidgetView(entry: entry) }
                .appLocale()
        }
        .configurationDisplayName("오늘 진행도")
        .description("오늘의 햇빛 목표 달성 현황")
        .supportedFamilies([.systemSmall])
    }
}

struct CompactInfoWidget: Widget {
    let kind: String = "CompactInfoWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SunflowerWidgetProvider()) { entry in
            ProLockedWidget(isOpen: entry.isOpen) { CompactInfoWidgetView(entry: entry) }
                .appLocale()
        }
        .configurationDisplayName("종합 정보")
        .description("햇빛 배터리와 오늘의 햇빛을 한눈에")
        .supportedFamilies([.systemMedium])
    }
}

struct DashboardWidget: Widget {
    let kind: String = "DashboardWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SunflowerWidgetProvider()) { entry in
            ProLockedWidget(isOpen: entry.isOpen) { DashboardWidgetView(entry: entry) }
                .appLocale()
        }
        .configurationDisplayName("대시보드")
        .description("전체 정보를 한눈에 확인")
        .supportedFamilies([.systemLarge])
    }
}

// MARK: - Preview
#Preview(as: .systemSmall) {
    SunflowerWidget()
} timeline: {
    SunflowerEntry.placeholder
}

#Preview(as: .systemSmall) {
    TodayProgressWidget()
} timeline: {
    SunflowerEntry.placeholder
}

#Preview(as: .systemMedium) {
    CompactInfoWidget()
} timeline: {
    SunflowerEntry.placeholder
}

#Preview(as: .systemLarge) {
    DashboardWidget()
} timeline: {
    SunflowerEntry.placeholder
}

//
//  SunflowerComplication.swift
//  SunlightWatchWidget
//
//  손목을 들 때마다 보이는 값: 해바라기 상태와 오늘 햇빛 진행률.
//  에너지는 시간마다 일정하게 줄어서, 다음 몇 시간의 모습을 미리 그려 둔다.
//

import SwiftUI
import WidgetKit

@main
struct SunlightWatchWidgets: WidgetBundle {
    var body: some Widget { SunflowerComplication() }
}

struct SunflowerEntry: TimelineEntry {
    let date: Date
    let minutes: Int
    let goal: Int
    let energy: Double

    var progress: Double { goal > 0 ? min(Double(minutes) / Double(goal), 1) : 0 }
    var mood: SunflowerMood { SunflowerMood(energy: energy) }

    static func at(_ date: Date) -> SunflowerEntry {
        SunflowerEntry(date: date,
                       minutes: WatchStore.todayMinutes(at: date),
                       goal: WatchStore.goalMinutes(),
                       energy: WatchStore.snapshot?.energy(at: date) ?? 100)
    }
}

struct SunflowerProvider: TimelineProvider {
    func placeholder(in context: Context) -> SunflowerEntry {
        SunflowerEntry(date: .now, minutes: 18, goal: 30, energy: 85)
    }

    func getSnapshot(in context: Context, completion: @escaping (SunflowerEntry) -> Void) {
        completion(context.isPreview ? placeholder(in: context) : .at(.now))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SunflowerEntry>) -> Void) {
        let now = Date()
        let entries = (0..<6).map { SunflowerEntry.at(now.addingTimeInterval(Double($0) * 3600)) }
        completion(Timeline(entries: entries, policy: .atEnd))
    }
}

struct SunflowerComplication: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "SunflowerComplication", provider: SunflowerProvider()) { entry in
            SunflowerComplicationView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("해바라기")
        .description("해바라기 상태와 오늘 받은 햇빛")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular, .accessoryCorner, .accessoryInline])
    }
}

struct SunflowerComplicationView: View {
    @Environment(\.widgetFamily) private var family
    let entry: SunflowerEntry

    var body: some View {
        content
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text("오늘의 햇빛"))
            .accessibilityValue(Text("\(entry.minutes) / \(entry.goal)분") + Text(verbatim: ", ") + Text(entry.mood.title))
    }

    @ViewBuilder private var content: some View {
        switch family {
        case .accessoryRectangular:
            HStack(spacing: 8) {
                SunflowerMark(energy: entry.energy)
                    .frame(width: 40, height: 40)
                    .widgetAccentable()
                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.mood.title)
                        .font(.headline)
                        .widgetAccentable()
                    Text("\(entry.minutes) / \(entry.goal)분")
                        .font(.system(.body, design: .rounded))
                    ProgressView(value: entry.progress)
                        .tint(.orange)
                }
            }
        case .accessoryCorner:
            SunflowerMark(energy: entry.energy)
                .padding(2)
                .widgetAccentable()
                .widgetLabel {
                    Gauge(value: entry.progress) {
                        Text(verbatim: "")
                    } currentValueLabel: {
                        Text("\(entry.minutes)분")
                    }
                    .tint(.orange)
                }
        case .accessoryInline:
            Label {
                Text("햇빛 \(entry.minutes)/\(entry.goal)분")
            } icon: {
                Image(systemName: "sun.max.fill")
            }
        default:
            Gauge(value: entry.progress) {
                Image(systemName: "sun.max.fill")
            } currentValueLabel: {
                SunflowerMark(energy: entry.energy).padding(1)
            }
            .gaugeStyle(.accessoryCircularCapacity)
            .tint(.orange)
            .widgetAccentable()
        }
    }
}

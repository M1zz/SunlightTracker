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
        let entry = loadEntry()
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
        return SunflowerEntry(date: Date(), widgetData: data)
    }
}

// MARK: - Timeline Entry
struct SunflowerEntry: TimelineEntry {
    let date: Date
    let widgetData: WidgetData

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

// MARK: - 해바라기 위젯 (Small)
struct SunflowerWidgetView: View {
    var entry: SunflowerEntry

    var body: some View {
        VStack(spacing: 8) {
            // 미니 해바라기
            MiniSunflowerView(energy: entry.widgetData.sunflowerEnergy, size: 80)

            // 건강 상태
            VStack(spacing: 4) {
                Text(healthStateText)
                    .font(.caption.bold())
                    .foregroundColor(healthColor)

                Text("에너지 \(Int(entry.widgetData.sunflowerEnergy))%")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }

    private var healthStateText: String {
        switch entry.widgetData.healthState {
        case "thriving": return "싱싱함"
        case "healthy": return "건강함"
        case "wilting": return "시들어감"
        case "critical": return "위험"
        default: return "건강함"
        }
    }

    private var healthColor: Color {
        switch entry.widgetData.healthState {
        case "thriving": return .green
        case "healthy": return Color(red: 0.5, green: 0.7, blue: 0.3)
        case "wilting": return .orange
        case "critical": return .red
        default: return .green
        }
    }
}

// MARK: - 배터리 위젯 (Small)
struct BatteryWidgetView: View {
    var entry: SunflowerEntry

    var body: some View {
        VStack(spacing: 8) {
            Spacer(minLength: 0)

            // 제목
            HStack {
                Image(systemName: "bolt.fill")
                    .foregroundColor(.green)
                    .font(.caption)
                Text("충전된 배터리")
                    .font(.caption.bold())
            }

            // 배터리 퍼센트 (큰 숫자)
            Text("\(Int(entry.widgetData.batteryPercentage))%")
                .font(.system(size: 40, weight: .bold))
                .foregroundColor(.green)

            // 5등분 배터리 세그먼트
            HStack(spacing: 3) {
                ForEach(0..<5, id: \.self) { index in
                    let segmentThreshold = Double((index + 1) * 20)
                    let isFilled = entry.widgetData.batteryPercentage >= segmentThreshold - 10

                    if index == 4 {
                        // 마지막 칸 - 배터리 팁
                        HStack(spacing: 0) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(isFilled ? Color.green : Color.gray.opacity(0.3))
                                .frame(height: 14)

                            RoundedRectangle(cornerRadius: 1)
                                .fill(isFilled ? Color.green : Color.gray.opacity(0.3))
                                .frame(width: 2, height: 7)
                        }
                    } else {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(isFilled ? Color.green : Color.gray.opacity(0.3))
                            .frame(height: 14)
                    }
                }
            }

            // 마지막 충전 시간
            Text(timeAgo(from: entry.widgetData.lastChargeTime))
                .font(.system(size: 9))
                .foregroundColor(.secondary)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }

    private func timeAgo(from date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        let hours = Int(interval / 3600)

        if hours < 1 {
            return "방금 충전"
        } else if hours < 24 {
            return "\(hours)시간 전"
        } else {
            let days = hours / 24
            return "\(days)일 전"
        }
    }
}

// MARK: - 오늘 진행도 위젯 (Small)
struct TodayProgressWidgetView: View {
    var entry: SunflowerEntry

    private var progress: Double {
        guard entry.widgetData.goalMinutes > 0 else { return 0 }
        return min(Double(entry.widgetData.todayMinutes) / Double(entry.widgetData.goalMinutes), 1.0)
    }

    var body: some View {
        VStack(spacing: 12) {
            Spacer(minLength: 0)

            // 원형 진행도
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 12)
                    .frame(width: 95, height: 95)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        progress >= 1.0 ? Color.green : Color.orange,
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .frame(width: 95, height: 95)
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 2) {
                    Text("\(Int(progress * 100))%")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(progress >= 1.0 ? .green : .orange)

                    if progress >= 1.0 {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
            }
            .padding(.vertical, 8)

            // 시간 정보
            Text("\(entry.widgetData.todayMinutes) / \(entry.widgetData.goalMinutes)분")
                .font(.caption.bold())
                .foregroundColor(.secondary)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

// MARK: - 종합 정보 위젯 (Medium)
struct CompactInfoWidgetView: View {
    var entry: SunflowerEntry

    private var progress: Double {
        guard entry.widgetData.goalMinutes > 0 else { return 0 }
        return min(Double(entry.widgetData.todayMinutes) / Double(entry.widgetData.goalMinutes), 1.0)
    }

    var body: some View {
        HStack(spacing: 16) {
            // 해바라기
            VStack(spacing: 4) {
                MiniSunflowerView(energy: entry.widgetData.sunflowerEnergy, size: 60)
                Text("\(Int(entry.widgetData.sunflowerEnergy))%")
                    .font(.caption.bold())
                    .foregroundColor(.green)
            }

            Divider()

            // 오늘 진행도
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "sun.max.fill")
                        .foregroundColor(.orange)
                        .font(.caption)
                    Text("오늘의 햇빛")
                        .font(.caption.bold())
                }

                Text("\(entry.widgetData.todayMinutes)분")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(progress >= 1.0 ? .green : .orange)

                Text("목표: \(entry.widgetData.goalMinutes)분")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Divider()

            // 배터리
            VStack(spacing: 4) {
                Image(systemName: "bolt.circle.fill")
                    .font(.largeTitle)
                    .foregroundColor(.green)

                Text("\(Int(entry.widgetData.batteryPercentage))%")
                    .font(.headline.bold())
                    .foregroundColor(.green)

                Text("충전량")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

// MARK: - 대시보드 위젯 (Large)
struct DashboardWidgetView: View {
    var entry: SunflowerEntry

    private var progress: Double {
        guard entry.widgetData.goalMinutes > 0 else { return 0 }
        return min(Double(entry.widgetData.todayMinutes) / Double(entry.widgetData.goalMinutes), 1.0)
    }

    var body: some View {
        VStack(spacing: 12) {
            // 상단: 해바라기 + 배터리
            HStack(spacing: 16) {
                // 해바라기
                VStack(spacing: 8) {
                    MiniSunflowerView(energy: entry.widgetData.sunflowerEnergy, size: 80)
                    Text(healthStateText)
                        .font(.caption.bold())
                        .foregroundColor(healthColor)
                    Text("에너지 \(Int(entry.widgetData.sunflowerEnergy))%")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)

                // 배터리
                VStack(spacing: 8) {
                    Image(systemName: "bolt.circle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.green)

                    Text("\(Int(entry.widgetData.batteryPercentage))%")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.green)

                    HStack(spacing: 2) {
                        ForEach(0..<5, id: \.self) { index in
                            let threshold = Double((index + 1) * 20)
                            let filled = entry.widgetData.batteryPercentage >= threshold - 10

                            if index == 4 {
                                HStack(spacing: 0) {
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(filled ? Color.green : Color.gray.opacity(0.3))
                                        .frame(height: 12)
                                    RoundedRectangle(cornerRadius: 1)
                                        .fill(filled ? Color.green : Color.gray.opacity(0.3))
                                        .frame(width: 2, height: 6)
                                }
                            } else {
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(filled ? Color.green : Color.gray.opacity(0.3))
                                    .frame(height: 12)
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity)
            }

            Divider()

            // 하단: 오늘 진행도
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "sun.max.fill")
                        .foregroundColor(.orange)
                    Text("오늘의 햇빛")
                        .font(.headline)
                    Spacer()
                    Text("\(entry.widgetData.todayMinutes) / \(entry.widgetData.goalMinutes)분")
                        .font(.subheadline.bold())
                        .foregroundColor(progress >= 1.0 ? .green : .orange)
                }

                // 진행도 바
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.2))

                        RoundedRectangle(cornerRadius: 8)
                            .fill(progress >= 1.0 ? Color.green : Color.orange)
                            .frame(width: geo.size.width * progress)
                    }
                }
                .frame(height: 16)

                if progress >= 1.0 {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("목표 달성!")
                            .font(.caption.bold())
                            .foregroundColor(.green)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }

    private var healthStateText: String {
        switch entry.widgetData.healthState {
        case "thriving": return "싱싱함"
        case "healthy": return "건강함"
        case "wilting": return "시들어감"
        case "critical": return "위험"
        default: return "건강함"
        }
    }

    private var healthColor: Color {
        switch entry.widgetData.healthState {
        case "thriving": return .green
        case "healthy": return Color(red: 0.5, green: 0.7, blue: 0.3)
        case "wilting": return .orange
        case "critical": return .red
        default: return .green
        }
    }
}

// MARK: - Mini Sunflower Component
struct MiniSunflowerView: View {
    let energy: Double
    let size: CGFloat

    init(energy: Double, size: CGFloat = 60) {
        self.energy = energy
        self.size = size
    }

    private var healthState: String {
        if energy >= 80 { return "thriving" }
        if energy >= 50 { return "healthy" }
        if energy >= 20 { return "wilting" }
        return "critical"
    }

    private var petalColor: Color {
        switch healthState {
        case "thriving": return Color(red: 1.0, green: 0.84, blue: 0.0)
        case "healthy": return Color(red: 1.0, green: 0.75, blue: 0.2)
        case "wilting": return Color(red: 0.8, green: 0.6, blue: 0.3)
        case "critical": return Color(red: 0.6, green: 0.4, blue: 0.2)
        default: return .yellow
        }
    }

    private var faceColor: Color {
        switch healthState {
        case "thriving": return Color(red: 0.4, green: 0.25, blue: 0.0)
        case "healthy": return Color(red: 0.35, green: 0.22, blue: 0.0)
        case "wilting": return Color(red: 0.3, green: 0.2, blue: 0.1)
        case "critical": return Color(red: 0.25, green: 0.18, blue: 0.12)
        default: return .brown
        }
    }

    private var petalDroop: Double {
        switch healthState {
        case "thriving": return 0
        case "healthy": return 0.15
        case "wilting": return 0.35
        case "critical": return 0.5
        default: return 0
        }
    }

    var body: some View {
        ZStack {
            // 8개의 꽃잎
            ForEach(0..<8, id: \.self) { index in
                Petal(droop: petalDroop)
                    .fill(petalColor)
                    .frame(width: size * 0.35, height: size * 0.55)
                    .offset(y: -size * 0.28)
                    .rotationEffect(.degrees(Double(index) * 45))
            }

            // 중앙 얼굴
            Circle()
                .fill(faceColor)
                .frame(width: size * 0.42, height: size * 0.42)
        }
        .frame(width: size, height: size)
    }
}

struct Petal: Shape {
    let droop: Double

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        let droopOffset = height * droop * 0.3

        path.move(to: CGPoint(x: width / 2, y: height + droopOffset))
        path.addQuadCurve(
            to: CGPoint(x: width / 2, y: droopOffset),
            control: CGPoint(x: 0, y: height / 2 + droopOffset)
        )
        path.addQuadCurve(
            to: CGPoint(x: width / 2, y: height + droopOffset),
            control: CGPoint(x: width, y: height / 2 + droopOffset)
        )
        path.closeSubpath()

        return path
    }
}

// MARK: - 위젯 설정들

struct SunflowerWidget: Widget {
    let kind: String = "SunflowerWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SunflowerWidgetProvider()) { entry in
            SunflowerWidgetView(entry: entry)
        }
        .configurationDisplayName("해바라기")
        .description("해바라기의 건강 상태를 확인하세요")
        .supportedFamilies([.systemSmall])
    }
}

struct BatteryWidget: Widget {
    let kind: String = "BatteryWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SunflowerWidgetProvider()) { entry in
            BatteryWidgetView(entry: entry)
        }
        .configurationDisplayName("배터리")
        .description("충전된 배터리 양을 확인하세요")
        .supportedFamilies([.systemSmall])
    }
}

struct TodayProgressWidget: Widget {
    let kind: String = "TodayProgressWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SunflowerWidgetProvider()) { entry in
            TodayProgressWidgetView(entry: entry)
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
            CompactInfoWidgetView(entry: entry)
        }
        .configurationDisplayName("종합 정보")
        .description("해바라기, 오늘 햇빛, 배터리를 한눈에")
        .supportedFamilies([.systemMedium])
    }
}

struct DashboardWidget: Widget {
    let kind: String = "DashboardWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SunflowerWidgetProvider()) { entry in
            DashboardWidgetView(entry: entry)
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
    BatteryWidget()
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

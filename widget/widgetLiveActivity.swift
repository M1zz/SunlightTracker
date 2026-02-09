//
//  widgetLiveActivity.swift
//  widget
//
//  Created by Leeo on 2/9/26.
//

import ActivityKit
import WidgetKit
import SwiftUI

// MARK: - Live Activity Widget
struct SunflowerLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: SunlightTrackingAttributes.self) { context in
            // Lock screen/banner UI
            LockScreenLiveActivityView(context: context)
                .activityBackgroundTint(Color.orange.opacity(0.2))
                .activitySystemActionForegroundColor(Color.orange)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI - all regions
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 4) {
                        Image(systemName: "leaf.circle.fill")
                            .foregroundColor(.green)
                            .font(.title3)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("햇빛 트래킹")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text("\(context.state.elapsedMinutes)분")
                                .font(.headline)
                                .fontWeight(.bold)
                        }
                    }
                }

                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 2) {
                        HStack(spacing: 4) {
                            Image(systemName: "bolt.fill")
                                .foregroundColor(.yellow)
                                .font(.caption)
                            Text("+\(Int(context.state.estimatedBatteryGain))%")
                                .font(.headline)
                                .fontWeight(.bold)
                        }
                        Text("예상 충전")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }

                DynamicIslandExpandedRegion(.center) {
                    // 조도 게이지
                    LuxGaugeView(lux: context.state.currentLux, compact: false)
                }

                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        // 해바라기 에너지
                        HStack(spacing: 4) {
                            Image(systemName: "leaf.fill")
                                .foregroundColor(.green)
                                .font(.caption)
                            Text("\(Int(context.state.sunflowerEnergy))%")
                                .font(.caption)
                                .fontWeight(.semibold)
                        }

                        Spacer()

                        // 조도 배터리 뷰
                        LuxBatteryView(lux: context.state.currentLux)

                        Spacer()

                        // 예상 충전량
                        HStack(spacing: 4) {
                            Image(systemName: "bolt.fill")
                                .foregroundColor(.yellow)
                                .font(.caption)
                            Text("+\(Int(context.state.estimatedBatteryGain))%")
                                .font(.caption)
                                .fontWeight(.semibold)
                        }
                    }
                    .padding(.horizontal, 8)
                }

            } compactLeading: {
                // Compact leading - 해바라기 아이콘
                Image(systemName: "leaf.circle.fill")
                    .foregroundColor(.green)

            } compactTrailing: {
                // Compact trailing - 예상 충전량
                Text("+\(Int(context.state.estimatedBatteryGain))%")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(.yellow)

            } minimal: {
                // Minimal - 배터리 아이콘
                Image(systemName: "bolt.fill")
                    .foregroundColor(.yellow)
            }
            .widgetURL(URL(string: "sunflowertracker://tracking"))
            .keylineTint(Color.green)
        }
    }
}

// MARK: - Lock Screen View
struct LockScreenLiveActivityView: View {
    let context: ActivityViewContext<SunlightTrackingAttributes>

    var body: some View {
        VStack(spacing: 12) {
            // 헤더
            HStack {
                Image(systemName: "sun.max.fill")
                    .foregroundColor(.orange)
                Text("햇빛 트래킹 중")
                    .font(.headline)
                Spacer()
                Text("\(context.state.elapsedMinutes)분 경과")
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }

            // 상태 정보
            HStack(spacing: 16) {
                // 조도
                VStack(alignment: .leading, spacing: 4) {
                    Text("조도")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    HStack(spacing: 4) {
                        Image(systemName: "light.max")
                            .font(.caption)
                        Text("\(luxFormatted(context.state.currentLux)) lux")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                }

                Spacer()

                // 예상 충전량
                VStack(alignment: .leading, spacing: 4) {
                    Text("예상 충전")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    HStack(spacing: 4) {
                        Image(systemName: "bolt.fill")
                            .foregroundColor(.yellow)
                            .font(.caption)
                        Text("+\(Int(context.state.estimatedBatteryGain))%")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                }

                Spacer()

                // 해바라기 에너지
                VStack(alignment: .leading, spacing: 4) {
                    Text("해바라기")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    HStack(spacing: 4) {
                        Image(systemName: "leaf.fill")
                            .foregroundColor(.green)
                            .font(.caption)
                        Text("\(Int(context.state.sunflowerEnergy))%")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                }
            }
        }
        .padding()
    }

    private func luxFormatted(_ lux: Double) -> String {
        if lux >= 10000 {
            return String(format: "%.0fk", lux / 1000)
        } else if lux >= 1000 {
            return String(format: "%.1fk", lux / 1000)
        } else {
            return String(format: "%.0f", lux)
        }
    }
}

// MARK: - Lux Gauge View
struct LuxGaugeView: View {
    let lux: Double
    let compact: Bool

    private var fillRatio: Double {
        min(lux / 10000, 1.0)
    }

    private var barColor: Color {
        if lux >= 10000 { return .red }
        if lux >= 5000 { return .orange }
        if lux >= 1000 { return .yellow }
        return .green
    }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                // 배경
                RoundedRectangle(cornerRadius: compact ? 2 : 4)
                    .fill(Color.gray.opacity(0.2))

                // 채움
                RoundedRectangle(cornerRadius: compact ? 2 : 4)
                    .fill(barColor)
                    .frame(width: geo.size.width * CGFloat(fillRatio))
            }
        }
        .frame(height: compact ? 4 : 8)
    }
}

// MARK: - Lux Battery View
struct LuxBatteryView: View {
    let lux: Double

    private var fillRatio: Double {
        min(lux / 10000, 1.0)
    }

    private var barColor: Color {
        if lux >= 10000 { return .red }
        if lux >= 5000 { return .orange }
        if lux >= 1000 { return .yellow }
        return .green
    }

    var body: some View {
        HStack(spacing: 2) {
            // 배터리 몸통
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 2)
                    .stroke(Color.gray, lineWidth: 1)
                    .frame(width: 30, height: 12)

                RoundedRectangle(cornerRadius: 1)
                    .fill(barColor)
                    .frame(width: 28 * CGFloat(fillRatio), height: 10)
                    .padding(.leading, 1)
            }

            // 배터리 팁
            RoundedRectangle(cornerRadius: 1)
                .fill(Color.gray)
                .frame(width: 2, height: 6)
        }
    }
}

// MARK: - Preview
#Preview("Notification", as: .content, using: SunlightTrackingAttributes.preview) {
   SunflowerLiveActivity()
} contentStates: {
    SunlightTrackingAttributes.ContentState.active
    SunlightTrackingAttributes.ContentState.late
}

extension SunlightTrackingAttributes {
    fileprivate static var preview: SunlightTrackingAttributes {
        SunlightTrackingAttributes(sessionStartTime: Date(), initialEnergy: 75)
    }
}

extension SunlightTrackingAttributes.ContentState {
    fileprivate static var active: SunlightTrackingAttributes.ContentState {
        SunlightTrackingAttributes.ContentState(
            elapsedMinutes: 5,
            currentLux: 8500,
            estimatedBatteryGain: 15,
            sunflowerEnergy: 75,
            lastUpdate: Date()
        )
    }

    fileprivate static var late: SunlightTrackingAttributes.ContentState {
        SunlightTrackingAttributes.ContentState(
            elapsedMinutes: 25,
            currentLux: 12000,
            estimatedBatteryGain: 60,
            sunflowerEnergy: 65,
            lastUpdate: Date()
        )
    }
}

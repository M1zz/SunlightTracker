//
//  widgetLiveActivity.swift
//  widget
//
//  밖에 나가 있는 동안 잠금 화면 · 다이나믹 아일랜드에 흐르는 것: 지금까지 밖에 있던 시간과 햇빛 배터리.
//

import ActivityKit
import WidgetKit
import SwiftUI

extension SunlightTrackingAttributes.ContentState {
    /// 받는 중인 몫까지 더한 햇빛 배터리
    var batteryLevel: Double { min(100, sunflowerEnergy + estimatedBatteryGain) }
}

// MARK: - Live Activity Widget
struct SunflowerLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: SunlightTrackingAttributes.self) { context in
            LockScreenLiveActivityView(state: context.state)
                .appLocale()
                .activityBackgroundTint(SunPalette.skyTop)
                .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    SunRays(level: context.state.batteryLevel)
                        .frame(width: 44, height: 44)
                        .padding(.leading, 4)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(verbatim: "\(Int(context.state.batteryLevel))%")
                        .font(.system(.title2, design: .rounded).weight(.bold))
                        .foregroundStyle(SunPalette.sun)
                        .padding(.trailing, 4)
                }
                DynamicIslandExpandedRegion(.center) {
                    VStack(spacing: 2) {
                        Text("햇빛 트래킹 중")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("\(context.state.elapsedMinutes)분")
                            .font(.system(.title2, design: .rounded).weight(.bold))
                            .appLocale()
                    }
                }
            } compactLeading: {
                Image(systemName: "sun.max.fill")
                    .foregroundStyle(SunPalette.sun)
            } compactTrailing: {
                Text("\(context.state.elapsedMinutes)분")
                    .font(.caption2.weight(.bold))
                    .appLocale()
                    .foregroundStyle(SunPalette.sun)
            } minimal: {
                Image(systemName: "sun.max.fill")
                    .foregroundStyle(SunPalette.sun)
            }
            .widgetURL(URL(string: "sunflowertracker://tracking"))
            .keylineTint(SunPalette.sun)
        }
    }
}

// MARK: - Lock Screen View
struct LockScreenLiveActivityView: View {
    let state: SunlightTrackingAttributes.ContentState

    var body: some View {
        HStack(spacing: 16) {
            SunRays(level: state.batteryLevel)
                .frame(width: 56, height: 56)
            VStack(alignment: .leading, spacing: 2) {
                Text("햇빛 트래킹 중")
                    .font(.subheadline)
                    .opacity(0.85)
                Text("\(state.elapsedMinutes)분 경과")
                    .font(.system(.title2, design: .rounded).weight(.bold))
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("햇빛 배터리")
                    .font(.caption)
                    .opacity(0.85)
                Text(verbatim: "\(Int(state.batteryLevel))%")
                    .font(.system(.title3, design: .rounded).weight(.bold))
            }
        }
        .foregroundStyle(.white)
        .padding()
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

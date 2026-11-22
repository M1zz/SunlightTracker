//
//  SunlightWatchApp.swift
//  SunlightWatch
//
//  한 화면: 햇빛 배터리 · 오늘 받은 햇빛. 손목을 들 때 볼 값은 컴플리케이션이 맡는다.
//

import SwiftUI
import WatchKit

@main
struct SunlightWatchApp: App {
    @StateObject private var model = WatchModel()

    var body: some Scene {
        WindowGroup {
            WatchHomeView(model: model)
                .appLocale()
                .task { model.start(); scheduleRefresh() }
        }
        // 한 시간쯤마다 워치 건강 앱을 다시 읽어 컴플리케이션을 맞춘다 (폰이 없어도).
        .backgroundTask(.appRefresh("daylight")) {
            await model.refreshHealth()
            await scheduleRefresh()
        }
    }

    @MainActor private func scheduleRefresh() {
        WKApplication.shared().scheduleBackgroundRefresh(withPreferredDate: .now.addingTimeInterval(3600), userInfo: "daylight" as NSString) { _ in }
    }
}

struct WatchHomeView: View {
    @ObservedObject var model: WatchModel

    var body: some View {
        TimelineView(.periodic(from: .now, by: 60)) { context in
            let minutes = model.todayMinutes(at: context.date)
            let goal = WatchStore.goalMinutes()
            let progress = goal > 0 ? min(Double(minutes) / Double(goal), 1) : 0
            let level = model.snapshot?.energy(at: context.date) ?? 0

            ScrollView {
                VStack(spacing: 8) {
                    SunRays(level: level) {
                        Text(verbatim: "\(Int(level))%")
                            .font(.system(.body, design: .rounded).weight(.bold))
                            .minimumScaleFactor(0.5)
                            .foregroundStyle(SunPalette.ink)
                    }
                    .frame(width: 96, height: 96)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(Text("햇빛 배터리"))
                    .accessibilityValue(Text(verbatim: "\(Int(level))%"))

                    if model.snapshot == nil {
                        Text("아이폰에서 햇빛바라기를 열어 주세요")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    } else {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("오늘의 햇빛")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                            Text("\(minutes) / \(goal)분")
                                .font(.system(.title3, design: .rounded).weight(.bold))
                            ProgressView(value: progress)
                                .tint(SunPalette.sun)
                        }
                        .accessibilityElement(children: .combine)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .containerBackground(SunPalette.sky.opacity(0.6), for: .navigation)
        }
    }
}

//
//  SunlightWatchApp.swift
//  SunlightWatch
//
//  한 화면: 해바라기 · 오늘 햇빛 · "해바라기에게 주기". 손목을 들 때 볼 값은 컴플리케이션이 맡는다.
//

import SwiftUI
import WatchKit

@main
struct SunlightWatchApp: App {
    @StateObject private var model = WatchModel()

    var body: some Scene {
        WindowGroup {
            WatchHomeView(model: model)
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
            let energy = model.snapshot?.energy(at: context.date) ?? 100
            let mood = SunflowerMood(energy: energy)

            ScrollView {
                VStack(spacing: 4) {
                    ZStack {
                        Circle().stroke(Color.orange.opacity(0.25), lineWidth: 7)
                        Circle()
                            .trim(from: 0, to: progress)
                            .stroke(progress >= 1 ? Color.green : Color.orange,
                                    style: StrokeStyle(lineWidth: 7, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                        SunflowerMark(energy: energy).padding(12)
                    }
                    .frame(width: 86, height: 86)
                    .accessibilityElement()
                    .accessibilityLabel(Text("오늘의 햇빛"))
                    .accessibilityValue(Text("\(minutes) / \(goal)분"))

                    Text("\(minutes) / \(goal)분")
                        .font(.system(.title3, design: .rounded).weight(.bold))
                        .foregroundStyle(progress >= 1 ? .green : .orange)

                    if model.snapshot == nil {
                        Text("아이폰에서 햇빛바라기를 열어 주세요")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    } else {
                        HStack(spacing: 4) {
                            Text(mood.title).foregroundStyle(mood.color)
                            Text("에너지 \(Int(energy))%").foregroundStyle(.secondary)
                        }
                        .font(.footnote)
                        .accessibilityElement(children: .combine)
                    }

                    if let battery = model.snapshot?.battery, battery >= 1 {
                        Button { model.give() } label: {
                            Label { Text("배터리 전달") + Text(verbatim: " \(Int(battery))%") } icon: { Image(systemName: "bolt.fill") }
                        }
                        .tint(.orange)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
}

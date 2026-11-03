//
//  SunlightIntents.swift
//  SunlightTracker
//
//  "햇빛바라기, 오늘 햇빛 얼마나 받았어?" — 오늘 받은 햇빛과 목표까지 남은 시간을 알려 준다.
//  앱이 저장해 둔 오늘 기록(SunlightManager 와 같은 자리)을 읽는다.
//

import AppIntents
import Foundation

struct TodaySunlightIntent: AppIntent {
    static let title = LocalizedStringResource("오늘 받은 햇빛", comment: "Siri: how much sunlight I got today")
    static let description = IntentDescription(
        LocalizedStringResource("오늘 받은 햇빛과 목표까지 남은 시간을 알려 줍니다.", comment: "Siri: today's sunlight description")
    )

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let records = UserDefaults.standard.data(forKey: "sunlight_records_v2")
            .flatMap { try? JSONDecoder().decode([SunlightRecord].self, from: $0) } ?? []
        guard let today = records.first(where: { Calendar.current.isDateInToday($0.date) }), today.totalMinutes > 0 else {
            return .result(dialog: IntentDialog(LocalizedStringResource("오늘은 아직 햇빛을 받지 않았어요. 잠깐 나가 볼까요?", comment: "Siri: no sunlight yet today")))
        }
        let got = today.totalMinutes
        let goal = today.goalMinutes
        guard got < goal else {
            return .result(dialog: IntentDialog(LocalizedStringResource("오늘 햇빛 \(got)분, 목표를 채웠어요.", comment: "Siri: goal reached. Argument is minutes")))
        }
        return .result(dialog: IntentDialog(LocalizedStringResource("오늘 햇빛 \(got)분 받았어요. 목표까지 \(goal - got)분 남았어요.", comment: "Siri: sunlight so far. Arguments: minutes, minutes left")))
    }
}

struct SunlightShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: TodaySunlightIntent(),
            phrases: ["How much sunlight did I get in \(.applicationName)", "\(.applicationName) today"],
            shortTitle: "Today’s Sunlight",
            systemImageName: "sun.max"
        )
    }
}

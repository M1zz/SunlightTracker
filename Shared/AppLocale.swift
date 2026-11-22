//
//  AppLocale.swift
//  앱 · 위젯 · 워치가 함께 쓰는 숫자 · 달력 기준.
//
//  아랍어 기기(사우디 등)는 숫자를 ١٢٣ 으로, 달력을 히즈라력으로 낼 수 있다. 그런데 앱 글 속 숫자(30분 · 25%)와
//  해 위의 % 는 0~9 라 한 화면에 두 숫자가 섞인다. 그래서 **아랍어일 때만** 0~9 와 그레고리력으로 맞춘다.
//  다른 언어는 기기 설정을 그대로 따른다(태국어의 불기력 등).
//

import SwiftUI

enum AppLocale {
    /// 앱이 지금 아랍어로 보이는가 (기기 언어가 아니라 실제로 고른 번역)
    static var isArabic: Bool { Bundle.main.preferredLocalizations.first == "ar" }

    /// 숫자 · 날짜를 만들 때 쓰는 로케일
    static var locale: Locale {
        guard isArabic else { return .current }
        var components = Locale.Components(locale: .current)
        components.numberingSystem = Locale.NumberingSystem("latn")
        components.calendar = .gregorian
        return Locale(components: components)
    }

    /// 달력 칸 · 날짜 계산에 쓰는 달력
    static var calendar: Calendar {
        guard isArabic else { return .current }
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = locale
        calendar.timeZone = .current
        return calendar
    }
}

extension View {
    /// 이 화면 아래의 `Text` 숫자 · 날짜 · `DatePicker` 를 `AppLocale` 에 맞춘다.
    func appLocale() -> some View {
        environment(\.locale, AppLocale.locale)
            .environment(\.calendar, AppLocale.calendar)
    }
}

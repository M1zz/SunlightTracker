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

    /// 아이폰이 마지막으로 보내 준 햇빛 배터리 상태.
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

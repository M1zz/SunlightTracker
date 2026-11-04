//
//  WatchSnapshot.swift
//  iPhone 앱 → 워치 앱 · 컴플리케이션. 워치가 폰 없이도 해바라기를 그릴 만큼만 담는다(건강 데이터 원본은 없다).
//

import Foundation

struct WatchSnapshot: Codable, Equatable {
    /// 해바라기 에너지(0~100)와 그 값을 잰 때. 에너지는 시간마다 일정하게 줄어서 워치가 혼자 이어 셀 수 있다.
    var energy: Double
    var energyAt: Date
    var decayPerHour: Double
    /// 아직 해바라기에게 주지 않은 햇빛 배터리(0~100).
    var battery: Double
    /// `day` 하루 동안 받은 햇빛(카메라 + 건강 앱, 겹침 없이)과 목표.
    var todayMinutes: Int
    var goalMinutes: Int
    var day: Date
    /// 건강 앱 연동을 켰는가. 켰으면 워치도 제 건강 앱 기록을 읽는다.
    var daylightFromHealth: Bool

    static let messageKey = "snapshot"
    /// 워치에서 "해바라기에게 주기" 를 눌렀다는 표시.
    static let giveKey = "giveBattery"

    func energy(at date: Date) -> Double {
        max(0, energy - decayPerHour * max(0, date.timeIntervalSince(energyAt)) / 3600)
    }

    func minutes(on date: Date) -> Int {
        Calendar.current.isDate(day, inSameDayAs: date) ? todayMinutes : 0
    }

    var encoded: Data? { try? JSONEncoder().encode(self) }
    static func decode(_ data: Data?) -> WatchSnapshot? {
        data.flatMap { try? JSONDecoder().decode(WatchSnapshot.self, from: $0) }
    }
}

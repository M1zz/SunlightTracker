//
//  WatchModel.swift
//  SunlightWatch
//
//  아이폰에서 해바라기 상태를 받고, 워치 건강 앱에서 오늘 햇빛을 읽는다. 폰이 없어도 마지막 상태로 돈다.
//

import Foundation
import WatchConnectivity
import WidgetKit

@MainActor
final class WatchModel: NSObject, ObservableObject {
    @Published private(set) var snapshot: WatchSnapshot? = WatchStore.snapshot
    @Published private(set) var watchMinutes = WatchStore.watchMinutes(on: .now)

    override init() {
        super.init()
        #if DEBUG
        // 스토어 스크린샷용: Debug 빌드에서만 `-ScreenshotDemo 1` (모으는 중) · `2` (목표 채움) 으로 하루를 채운다.
        switch UserDefaults.standard.integer(forKey: "ScreenshotDemo") {
        case 1: save(WatchSnapshot(energy: 86, energyAt: .now, decayPerHour: 2.5, battery: 40,
                                   todayMinutes: 22, goalMinutes: 30, day: .now, daylightFromHealth: false))
        case 2: save(WatchSnapshot(energy: 97, energyAt: .now, decayPerHour: 2.5, battery: 0,
                                   todayMinutes: 34, goalMinutes: 30, day: .now, daylightFromHealth: false))
        default: break
        }
        #endif
    }

    func start() {
        if WCSession.isSupported(), WCSession.default.activationState != .activated {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
        Task { await refreshHealth() }
    }

    func todayMinutes(at date: Date) -> Int { WatchStore.todayMinutes(at: date) }

    /// 아이폰에서 건강 앱 연동을 켰을 때만 워치 건강 앱을 읽는다.
    func refreshHealth() async {
        guard snapshot?.daylightFromHealth == true else { return }
        if await DaylightHealth.shared.needsAsking() { await DaylightHealth.shared.requestAccess() }
        let now = Date()
        let minutes = DaylightPiece.minutes(await DaylightHealth.shared.todayPieces(now: now), excluding: [])
        guard minutes != WatchStore.watchMinutes(on: now) else { return }
        WatchStore.setWatchMinutes(minutes, at: now)
        watchMinutes = minutes
        WidgetCenter.shared.reloadAllTimelines()
    }

    /// 모은 햇빛 배터리를 해바라기에게. 폰이 멀리 있으면 가까워질 때 전해진다.
    func give() {
        guard var next = snapshot, next.battery >= 1 else { return }
        let now = Date()
        next.energy = min(100, next.energy(at: now) + next.battery)
        next.energyAt = now
        next.battery = 0
        save(next)
        WCSession.default.transferUserInfo([WatchSnapshot.giveKey: true])
    }

    private func save(_ next: WatchSnapshot) {
        WatchStore.snapshot = next
        snapshot = next
        WidgetCenter.shared.reloadAllTimelines()
    }

    fileprivate func receive(_ payload: [String: Any]) {
        #if DEBUG
        if UserDefaults.standard.integer(forKey: "ScreenshotDemo") != 0 { return }  // 찍는 동안 폰 상태로 덮지 않게
        #endif
        guard let next = WatchSnapshot.decode(payload[WatchSnapshot.messageKey] as? Data), next != snapshot else { return }
        save(next)
        Task { await refreshHealth() }
    }
}

extension WatchModel: WCSessionDelegate {
    nonisolated func session(_ session: WCSession, activationDidCompleteWith state: WCSessionActivationState, error: Error?) {
        let context = session.receivedApplicationContext
        Task { @MainActor in self.receive(context) }
    }

    nonisolated func session(_ session: WCSession, didReceiveApplicationContext context: [String: Any]) {
        Task { @MainActor in self.receive(context) }
    }

    /// 컴플리케이션용으로 온 상태도 같은 자리에 받는다.
    nonisolated func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
        Task { @MainActor in self.receive(userInfo) }
    }
}

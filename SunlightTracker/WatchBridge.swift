//
//  WatchBridge.swift
//  SunlightTracker
//
//  워치 앱과 잇는다. 햇빛 배터리와 오늘 받은 햇빛을 보낸다.
//

import Foundation
import WatchConnectivity

@MainActor
final class WatchBridge: NSObject {
    static let shared = WatchBridge()

    /// 연결이 열리거나 워치 앱이 깔리면 지금 상태를 다시 보내게 부른다.
    var onActivate: (() -> Void)?
    private var lastSent: WatchSnapshot?

    func activate() {
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    func send(_ snapshot: WatchSnapshot) {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        guard session.activationState == .activated, session.isPaired, session.isWatchAppInstalled,
              let data = snapshot.encoded else { return }
        // 분 · 배터리가 바뀌었을 때만 컴플리케이션을 깨운다 (하루 횟수가 정해져 있다).
        let changed = lastSent.map {
            $0.minutes(on: .now) != snapshot.minutes(on: .now) || Int($0.battery) != Int(snapshot.battery)
                || Int($0.energy(at: .now)) != Int(snapshot.energy(at: .now)) || $0.goalMinutes != snapshot.goalMinutes
        } ?? true
        guard changed else { return }
        lastSent = snapshot
        let payload = [WatchSnapshot.messageKey: data]
        try? session.updateApplicationContext(payload)
        if session.isComplicationEnabled, session.remainingComplicationUserInfoTransfers > 0 {
            session.transferCurrentComplicationUserInfo(payload)
        }
    }
}

extension WatchBridge: WCSessionDelegate {
    nonisolated func session(_ session: WCSession, activationDidCompleteWith state: WCSessionActivationState, error: Error?) {
        Task { @MainActor in self.lastSent = nil; self.onActivate?() }
    }
    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {}
    nonisolated func sessionDidDeactivate(_ session: WCSession) { session.activate() }
    nonisolated func sessionWatchStateDidChange(_ session: WCSession) {
        Task { @MainActor in self.lastSent = nil; self.onActivate?() }
    }

}

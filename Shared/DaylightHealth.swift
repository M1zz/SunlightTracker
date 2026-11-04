//
//  DaylightHealth.swift
//  iPhone 앱 · 워치 앱이 함께 쓴다.
//
//  건강 앱의 '햇빛 아래 있었던 시간'(Apple Watch 가 잰다)을 **읽기만** 한다.
//  기기 밖으로 보내지 않는다. 읽기 권한은 거절 여부를 알려 주지 않으므로, 거절하면 그냥 빈 값이 온다.
//

import Foundation
import HealthKit

@MainActor
final class DaylightHealth {
    static let shared = DaylightHealth()

    static var isAvailable: Bool { HKHealthStore.isHealthDataAvailable() }

    private let store = HKHealthStore()
    private let type = HKQuantityType(.timeInDaylight)
    private var observer: HKObserverQuery?

    /// 사용자가 켤 때만 부른다. 이미 답했으면 다시 묻지 않는다.
    func requestAccess() async {
        guard Self.isAvailable else { return }
        try? await store.requestAuthorization(toShare: [], read: [type])
    }

    /// 아직 한 번도 묻지 않았는가.
    func needsAsking() async -> Bool {
        guard Self.isAvailable else { return false }
        let status = try? await store.statusForAuthorizationRequest(toShare: [], read: [type])
        return status == .shouldRequest
    }

    /// 오늘의 5분 조각들: (구간, 그 안에서 햇빛 아래 있었던 분). 여러 기기가 같은 시간을 재도 한 번만 센다.
    func todayPieces(now: Date = .now) async -> [DaylightPiece] {
        guard Self.isAvailable else { return [] }
        let start = Calendar.current.startOfDay(for: now)
        let descriptor = HKStatisticsCollectionQueryDescriptor(
            predicate: .quantitySample(type: type, predicate: HKQuery.predicateForSamples(withStart: start, end: nil)),
            options: .cumulativeSum,
            anchorDate: start,
            intervalComponents: DateComponents(minute: 5)
        )
        guard let collection = try? await descriptor.result(for: store) else { return [] }
        var pieces: [DaylightPiece] = []
        collection.enumerateStatistics(from: start, to: now) { stats, _ in
            guard let sum = stats.sumQuantity() else { return }
            pieces.append(DaylightPiece(interval: DateInterval(start: stats.startDate, end: stats.endDate),
                                        minutes: sum.doubleValue(for: .minute())))
        }
        return pieces
    }

    /// 새 햇빛 기록이 들어오면 부른다. 앱이 꺼져 있어도 한 시간에 한 번쯤 깨운다.
    func startObserving(_ onChange: @escaping @MainActor () async -> Void) {
        guard Self.isAvailable, observer == nil else { return }
        let query = HKObserverQuery(sampleType: type, predicate: nil) { _, completion, error in
            Task { @MainActor in
                if error == nil { await onChange() }
                completion()
            }
        }
        store.execute(query)
        observer = query
        store.enableBackgroundDelivery(for: type, frequency: .hourly) { _, _ in }
    }

    func stopObserving() {
        if let observer { store.stop(observer) }
        observer = nil
        store.disableBackgroundDelivery(for: type) { _, _ in }
    }
}

/// 건강 앱 햇빛 기록 한 조각.
struct DaylightPiece {
    let interval: DateInterval
    let minutes: Double

    /// 조각들 중 `covered`(카메라로 이미 잰 구간)와 겹치지 않는 몫의 분. 같은 시간대는 한 번만 센다.
    static func minutes(_ pieces: [DaylightPiece], excluding covered: [DateInterval]) -> Int {
        let total = pieces.reduce(0.0) { sum, piece in
            let length = piece.interval.duration
            guard length > 0 else { return sum }
            let overlap = covered.reduce(0.0) { $0 + (piece.interval.intersection(with: $1)?.duration ?? 0) }
            return sum + piece.minutes * (1 - min(overlap, length) / length)
        }
        return Int(total.rounded())
    }
}

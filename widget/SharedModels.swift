//
//  SharedModels.swift
//  widget
//
//  Created by Leeo on 2/9/26.
//

import Foundation

// MARK: - Shared Data Manager
class SharedDataManager {
    static let shared = SharedDataManager()
    private let appGroupID = "group.com.leeo.sunflower"
    private let sharedDefaults: UserDefaults?
    private let widgetDataKey = "widget_data"

    init() {
        sharedDefaults = UserDefaults(suiteName: appGroupID)
    }

    func saveWidgetData(_ data: WidgetData) {
        guard let encoded = try? JSONEncoder().encode(data) else { return }
        sharedDefaults?.set(encoded, forKey: widgetDataKey)
    }

    func loadWidgetData() -> WidgetData? {
        guard let data = sharedDefaults?.data(forKey: widgetDataKey),
              let decoded = try? JSONDecoder().decode(WidgetData.self, from: data) else {
            return nil
        }
        return decoded
    }
}

// MARK: - Widget Data Model
struct WidgetData: Codable {
    let batteryPercentage: Double
    let lastChargeTime: Date
    let sunflowerEnergy: Double
    let healthState: String  // "thriving", "healthy", "wilting", "critical"
    let todayMinutes: Int
    let goalMinutes: Int
    let lastUpdate: Date

    // 트래킹 상태
    let isTracking: Bool
    let isConfirmedOutdoor: Bool
    let currentLux: Double
    let estimatedBatteryGain: Double
    let confirmedElapsedMinutes: Int

    var goalProgress: Double {
        guard goalMinutes > 0 else { return 0 }
        return min(Double(todayMinutes) / Double(goalMinutes), 1.0)
    }
}

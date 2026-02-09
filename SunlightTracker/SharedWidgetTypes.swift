//
//  SharedWidgetTypes.swift
//  SunlightTracker
//
//  Shared types for both main app and widget extension
//

import Foundation
import ActivityKit

// MARK: - Activity Attributes
struct SunlightTrackingAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var elapsedMinutes: Int
        var currentLux: Double
        var estimatedBatteryGain: Double
        var sunflowerEnergy: Double
        var lastUpdate: Date
    }

    // Static attributes
    var sessionStartTime: Date
    var initialEnergy: Double
}

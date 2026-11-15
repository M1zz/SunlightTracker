//
//  widgetBundle.swift
//  widget
//
//  Created by Leeo on 2/9/26.
//

import WidgetKit
import SwiftUI

@main
struct SunflowerWidgetBundle: WidgetBundle {
    var body: some Widget {
        // Small 위젯들
        SunflowerWidget()       // 햇빛 배터리
        TodayProgressWidget()

        // Medium 위젯
        CompactInfoWidget()

        // Large 위젯
        DashboardWidget()

        // Live Activity
        SunflowerLiveActivity()
    }
}

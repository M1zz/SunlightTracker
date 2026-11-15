//
//  SunRays.swift
//  앱 · 위젯 · 워치가 함께 쓰는 햇빛 배터리 그림.
//  해 둘레의 빛살 12개가 남은 배터리만큼 켜진다. 앱 아이콘과 같은 모양 · 같은 색.
//

import SwiftUI

enum SunPalette {
    /// 맑은 한낮 하늘: 위 짙은 파랑 → 아래 맑은 하늘색
    static let skyTop = Color(red: 0.16, green: 0.51, blue: 0.94)
    static let skyBottom = Color(red: 0.43, green: 0.75, blue: 1.0)
    static let sun = Color(red: 1.0, green: 0.84, blue: 0.16)
    /// 빈 해: 하늘이 비치지 않는 옅은 흰빛 (반투명이면 파랑과 섞여 초록빛이 돈다)
    static let emptySun = Color(red: 0.86, green: 0.93, blue: 1.0)
    /// 해 위의 숫자
    static let ink = Color(red: 0.08, green: 0.22, blue: 0.48)
    static var sky: LinearGradient {
        LinearGradient(colors: [skyTop, skyBottom], startPoint: .top, endPoint: .bottom)
    }
}

/// 빛살 게이지. 크기는 주어진 틀에 맞춘다(정사각형 기준).
struct SunRays<Center: View>: View {
    /// 남은 배터리 0~100
    let level: Double
    /// 켜진 빛살 색 (친구와 함께 받으면 물들일 수 있다)
    var rayColor: (Int) -> Color = { _ in SunPalette.sun }
    /// 꺼진 빛살
    var offColor: Color = .white.opacity(0.35)
    @ViewBuilder var center: () -> Center

    static var rayCount: Int { 12 }

    var body: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            let lit = min(max(level, 0), 100) / 100 * Double(Self.rayCount)
            ZStack {
                ForEach(0..<Self.rayCount, id: \.self) { i in
                    Capsule()
                        .fill(offColor)
                        .overlay(Capsule().fill(rayColor(i)).opacity(min(max(lit - Double(i), 0), 1)))
                        .frame(width: side * 0.10, height: side * 0.24)
                        .offset(y: -side * 0.38)
                        .rotationEffect(.degrees(Double(i) * 360 / Double(Self.rayCount)))
                }
                // 비어 있으면 흐린 해, 찰수록 노랗게 밝아진다
                Circle()
                    .fill(SunPalette.emptySun)
                    .overlay(Circle().fill(SunPalette.sun).opacity(min(max(level, 0), 100) / 100))
                    .frame(width: side * 0.48, height: side * 0.48)
                center()
                    .frame(width: side * 0.44, height: side * 0.44)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

extension SunRays where Center == EmptyView {
    init(level: Double, offColor: Color = .white.opacity(0.35)) {
        self.init(level: level, offColor: offColor) { EmptyView() }
    }
}

/// 남은 배터리를 지금 시각 기준으로 계산한다 (저장된 값은 마지막으로 잰 때의 것).
enum SunBattery {
    /// 기본 감소: 시간당 2.5% — 가득 차면 40시간 간다.
    static let decayPerHour = 2.5
    static func level(_ stored: Double, at stamp: Date, now: Date = .now, decayPerHour: Double = decayPerHour) -> Double {
        max(0, stored - decayPerHour * max(0, now.timeIntervalSince(stamp)) / 3600)
    }
}

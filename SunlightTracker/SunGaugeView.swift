import SwiftUI

/// 햇빛 배터리: 맑은 하늘에 뜬 해, 둘레의 빛살 12개가 남은 만큼 켜진다. 앱 아이콘과 같은 그림.
struct SunGaugeView: View {
    /// 남은 배터리 0~100
    let level: Double
    /// 이대로 두면 바닥날 때까지 남은 시간(시간)
    let hoursLeft: Double
    /// 밖에서 햇빛을 받는 중
    let isCharging: Bool
    /// 친구와 함께 받으면 켜진 빛살이 물든다
    var petals: PetalColorState = .defaultYellow

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var glow = false

    private static let rays = 12
    private let sun = Color(red: 1.0, green: 0.84, blue: 0.16)
    private let rayOn = Color(red: 1.0, green: 0.84, blue: 0.16)
    private let ink = Color(red: 0.08, green: 0.22, blue: 0.48)

    private var clamped: Double { min(max(level, 0), 100) }
    /// 켜진 빛살 수(소수). 마지막 하나는 남은 만큼 흐리게 켠다.
    private var litRays: Double { clamped / 100 * Double(Self.rays) }

    var body: some View {
        VStack(spacing: 18) {
            GeometryReader { geo in
                let side = min(geo.size.width, geo.size.height)
                ZStack {
                    ForEach(0..<Self.rays, id: \.self) { ray($0, side: side) }
                    Circle()
                        .fill(sun)
                        .frame(width: side * 0.40, height: side * 0.40)
                        .shadow(color: .white.opacity(glow ? 0.7 : 0.3), radius: glow ? side * 0.08 : side * 0.04)
                    VStack(spacing: 0) {
                        Text(verbatim: "\(Int(clamped.rounded()))")
                            .font(.system(size: side * 0.15, weight: .bold, design: .rounded))
                            .monospacedDigit()
                        + Text(verbatim: "%")
                            .font(.system(size: side * 0.07, weight: .semibold, design: .rounded))
                    }
                    .foregroundStyle(ink)
                    .contentTransition(.numericText())
                }
                .frame(width: geo.size.width, height: geo.size.height)
            }
            .frame(height: 240)
            .animation(.easeInOut(duration: 0.6), value: clamped)

            VStack(spacing: 4) {
                Text("햇빛 배터리")
                    .font(.headline)
                Text(caption)
                    .font(.subheadline)
                    .opacity(0.85)
            }
            .foregroundStyle(.white)
        }
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(LinearGradient(colors: [Color(red: 0.16, green: 0.51, blue: 0.94),
                                              Color(red: 0.43, green: 0.75, blue: 1.0)],
                                     startPoint: .top, endPoint: .bottom))
        )
        .onAppear { updateGlow() }
        .onChange(of: isCharging) { _, _ in updateGlow() }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("햇빛 배터리"))
        .accessibilityValue(Text(verbatim: "\(Int(clamped.rounded()))%, ") + Text(caption))
    }

    private var caption: LocalizedStringKey {
        if isCharging { return "충전 중" }
        if hoursLeft < 1 { return "곧 바닥나요" }
        return "약 \(Int(hoursLeft))시간 남음"
    }

    private func ray(_ index: Int, side: CGFloat) -> some View {
        let fill = min(max(litRays - Double(index), 0), 1)   // 0 꺼짐 · 1 켜짐
        let length = side * 0.17, width = side * 0.07
        return Capsule()
            .fill(Color.white.opacity(0.35))
            .overlay(Capsule().fill(rayColor(index)).opacity(fill))
            .frame(width: width, height: length)
            .offset(y: -side * 0.34)
            .rotationEffect(.degrees(Double(index) * 360 / Double(Self.rays)))
    }

    private func rayColor(_ index: Int) -> Color {
        guard petals.blendFactor > 0, index < petals.gradients.count else { return rayOn }
        let base = RGBColor(r: 1.0, g: 0.84, b: 0.16)
        return base.lerp(to: petals.gradients[index].top, t: petals.blendFactor).color
    }

    private func updateGlow() {
        guard isCharging, !reduceMotion else { withAnimation { glow = false }; return }
        withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) { glow = true }
    }
}

#Preview {
    VStack {
        SunGaugeView(level: 67, hoursLeft: 26, isCharging: false)
        SunGaugeView(level: 8, hoursLeft: 0.5, isCharging: true)
    }
    .padding()
}

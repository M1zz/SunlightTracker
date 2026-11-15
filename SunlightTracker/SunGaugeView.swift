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

    private var clamped: Double { min(max(level, 0), 100) }

    var body: some View {
        SunRays(level: clamped, rayColor: rayColor) {
            GeometryReader { geo in
                let side = geo.size.width
                VStack(spacing: 0) {
                    if isCharging {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: side * 0.16, weight: .bold))
                            .symbolEffect(.pulse, isActive: !reduceMotion)
                    }
                    (Text(verbatim: "\(Int(clamped.rounded()))")
                        .font(.system(size: side * 0.36, weight: .bold, design: .rounded))
                    + Text(verbatim: "%")
                        .font(.system(size: side * 0.16, weight: .semibold, design: .rounded)))
                    .monospacedDigit()
                    .contentTransition(.numericText())
                }
                .foregroundStyle(SunPalette.ink)
                .frame(width: geo.size.width, height: geo.size.height)
            }
        }
        .shadow(color: .white.opacity(glow ? 0.6 : 0), radius: glow ? 24 : 0)
        .frame(height: 320)
        .animation(.easeInOut(duration: 0.6), value: clamped)
        .padding(.vertical, 28)
        .frame(maxWidth: .infinity)
        .background(RoundedRectangle(cornerRadius: 32, style: .continuous).fill(SunPalette.sky))
        .onAppear { updateGlow() }
        .onChange(of: isCharging) { _, _ in updateGlow() }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("햇빛 배터리"))
        .accessibilityValue(Text(verbatim: "\(Int(clamped.rounded()))%, ") + Text(caption))
    }

    /// 화면에는 그림과 숫자만. 말은 VoiceOver 로만 전한다.
    private var caption: LocalizedStringKey {
        if isCharging { return "충전 중" }
        if clamped < 0.5 { return "밖에 나가면 차올라요" }
        if hoursLeft < 1 { return "곧 바닥나요" }
        return "약 \(Int(hoursLeft))시간 남음"
    }

    private func rayColor(_ index: Int) -> Color {
        guard petals.blendFactor > 0, index < petals.gradients.count else { return SunPalette.sun }
        return RGBColor(r: 1.0, g: 0.84, b: 0.16).lerp(to: petals.gradients[index].top, t: petals.blendFactor).color
    }

    private func updateGlow() {
        guard isCharging, !reduceMotion else { withAnimation { glow = false }; return }
        withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) { glow = true }
    }
}

#Preview {
    VStack {
        SunGaugeView(level: 67, hoursLeft: 26, isCharging: false)
        SunGaugeView(level: 0, hoursLeft: 0, isCharging: false)
    }
    .padding()
}

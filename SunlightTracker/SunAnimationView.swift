import SwiftUI

struct SunAnimationView: View {
    let health: Double  // 0~100
    let isTracking: Bool
    var petalColorState: PetalColorState = .defaultYellow
    @State private var swayAngle: Double = 0
    @State private var sparkleOpacity: Double = 0
    @State private var auraScale1: CGFloat = 1.0
    @State private var auraScale2: CGFloat = 1.0
    @State private var auraScale3: CGFloat = 1.0
    @State private var auraOpacity: Double = 0.0

    private var healthState: SunflowerHealth.HealthState {
        if health >= 80 { return .thriving }
        if health >= 50 { return .healthy }
        if health >= 20 { return .wilting }
        return .critical
    }

    // 꽃잎 각도 (시들면 아래로 처짐)
    private var petalDroop: Double {
        switch healthState {
        case .thriving: return 0
        case .healthy: return 15
        case .wilting: return 30
        case .critical: return 45
        }
    }

    // 얼굴 색상 (시들면 어두워짐)
    private var faceColor: Color {
        switch healthState {
        case .thriving: return .orange
        case .healthy: return Color(red: 1.0, green: 0.8, blue: 0.2)
        case .wilting: return Color(red: 0.8, green: 0.6, blue: 0.2)
        case .critical: return Color(red: 0.5, green: 0.4, blue: 0.2)
        }
    }

    // 꽃잎 색상
    private var petalColor: LinearGradient {
        switch healthState {
        case .thriving:
            return LinearGradient(
                colors: [Color(red: 1.0, green: 0.85, blue: 0.1), Color(red: 1.0, green: 0.7, blue: 0.0)],
                startPoint: .top, endPoint: .bottom
            )
        case .healthy:
            return LinearGradient(
                colors: [Color(red: 1.0, green: 0.8, blue: 0.2), Color(red: 1.0, green: 0.65, blue: 0.1)],
                startPoint: .top, endPoint: .bottom
            )
        case .wilting:
            return LinearGradient(
                colors: [Color(red: 0.8, green: 0.6, blue: 0.2), Color(red: 0.7, green: 0.5, blue: 0.1)],
                startPoint: .top, endPoint: .bottom
            )
        case .critical:
            return LinearGradient(
                colors: [Color(red: 0.6, green: 0.4, blue: 0.2), Color(red: 0.5, green: 0.3, blue: 0.1)],
                startPoint: .top, endPoint: .bottom
            )
        }
    }

    private var isFullBloom: Bool { healthState == .thriving }

    // 개별 꽃잎 그라데이션 (공유 활동 시 알록달록, 평소엔 건강 기반)
    private func petalGradient(for index: Int) -> LinearGradient {
        guard petalColorState.blendFactor > 0,
              index < petalColorState.gradients.count else {
            return petalColor
        }
        let grad = petalColorState.gradients[index]
        return LinearGradient(
            colors: [grad.top.color, grad.bottom.color],
            startPoint: .top, endPoint: .bottom
        )
    }

    var body: some View {
        ZStack {
            // 하늘 배경
            LinearGradient(
                colors: [
                    Color(red: 0.53, green: 0.81, blue: 0.98),
                    Color(red: 0.75, green: 0.9, blue: 1.0)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            // 태양 오라 (트래킹 중일 때만)
            if isTracking {
                ZStack {
                    // 오라 1 (가장 큰 원)
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.yellow.opacity(0.4),
                                    Color.orange.opacity(0.2),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 80
                            )
                        )
                        .frame(width: 160, height: 160)
                        .scaleEffect(auraScale1)
                        .opacity(auraOpacity * 0.6)

                    // 오라 2 (중간 원)
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.yellow.opacity(0.5),
                                    Color.orange.opacity(0.3),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 60
                            )
                        )
                        .frame(width: 120, height: 120)
                        .scaleEffect(auraScale2)
                        .opacity(auraOpacity * 0.7)

                    // 오라 3 (작은 원)
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.yellow.opacity(0.6),
                                    Color.orange.opacity(0.4),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 45
                            )
                        )
                        .frame(width: 90, height: 90)
                        .scaleEffect(auraScale3)
                        .opacity(auraOpacity * 0.8)
                }
                .blur(radius: 8)
                .transition(.opacity)
            }

            // 해바라기 (얼굴 + 꽃잎)
            ZStack {
                // 꽃잎 (12개 고정, 각도와 색상 변경)
                ForEach(0..<12, id: \.self) { i in
                    PetalShape()
                        .fill(petalGradient(for: i))
                        .frame(width: 16, height: 32)
                        .offset(y: -52)
                        .rotationEffect(.degrees(Double(i) * 30 + petalDroop))
                        .animation(.easeInOut(duration: 0.8), value: petalDroop)
                        .animation(.easeInOut(duration: 1.5), value: petalColorState.blendFactor)
                }

                // 얼굴 원
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [faceColor, faceColor.opacity(0.85)],
                            center: .center,
                            startRadius: 5,
                            endRadius: 40
                        )
                    )
                    .frame(width: 80, height: 80)
                    .shadow(color: faceColor.opacity(0.4), radius: isTracking ? 12 : 6)

                // 눈 + 입 + 썬글라스
                VStack(spacing: 6) {
                    ZStack {
                        // 기본 눈 (썬글라스 없을 때만 보임)
                        if !isTracking {
                            HStack(spacing: 16) {
                                Circle().fill(Color.white).frame(width: 8, height: 8)
                                Circle().fill(Color.white).frame(width: 8, height: 8)
                            }
                        }

                        // 썬글라스 (트래킹 중일 때)
                        if isTracking {
                            HStack(spacing: 4) {
                                // 왼쪽 렌즈
                                Ellipse()
                                    .fill(Color.black.opacity(0.85))
                                    .frame(width: 14, height: 10)
                                    .overlay(
                                        Ellipse()
                                            .stroke(Color.white.opacity(0.3), lineWidth: 0.5)
                                    )

                                // 브릿지
                                Rectangle()
                                    .fill(Color.black)
                                    .frame(width: 4, height: 2)

                                // 오른쪽 렌즈
                                Ellipse()
                                    .fill(Color.black.opacity(0.85))
                                    .frame(width: 14, height: 10)
                                    .overlay(
                                        Ellipse()
                                            .stroke(Color.white.opacity(0.3), lineWidth: 0.5)
                                    )
                            }
                            .transition(.scale.combined(with: .opacity))
                        }
                    }
                    .animation(.spring(duration: 0.4), value: isTracking)

                    if healthState == .thriving || healthState == .healthy {
                        // 웃는 입
                        Arc(startAngle: .degrees(0), endAngle: .degrees(180), clockwise: false)
                            .stroke(Color.white, lineWidth: 2.5)
                            .frame(width: 22, height: 11)
                    } else {
                        // 슬픈 입
                        Arc(startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
                            .stroke(Color.white, lineWidth: 2)
                            .frame(width: 16, height: 8)
                    }
                }
                .offset(y: -2)
                .animation(.easeInOut(duration: 0.5), value: healthState)

                // 만개 시 씨앗 패턴 (중심부 테두리)
                if isFullBloom {
                    Circle()
                        .strokeBorder(Color(red: 0.6, green: 0.4, blue: 0.15).opacity(0.3), lineWidth: 3)
                        .frame(width: 80, height: 80)
                }
            }
            .rotationEffect(.degrees(isTracking ? swayAngle : 0))

            // 만개 반짝이
            if isFullBloom {
                ForEach(0..<5, id: \.self) { i in
                    let positions: [(CGFloat, CGFloat)] = [
                        (-45, -50), (50, -40), (-35, 45), (40, 50), (0, -65)
                    ]
                    Image(systemName: "sparkle")
                        .font(.system(size: CGFloat.random(in: 8...12)))
                        .foregroundColor(.yellow.opacity(sparkleOpacity * Double.random(in: 0.5...1.0)))
                        .offset(x: positions[i].0, y: positions[i].1)
                }
            }

            // 건강도 텍스트
            VStack {
                Spacer()
                Text("\(Int(health))%")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Color.black.opacity(0.2))
                    .cornerRadius(12)
                    .padding(.bottom, 8)
            }
        }
        .frame(width: 240, height: 240)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .onAppear {
            if isTracking {
                startSwayAnimation()
                startAuraAnimation()
            }
            if isFullBloom { startSparkle() }
        }
        .onChange(of: isTracking) { _, newValue in
            if newValue {
                startSwayAnimation()
                startAuraAnimation()
            } else {
                withAnimation(.easeOut(duration: 0.5)) { swayAngle = 0 }
                stopAuraAnimation()
            }
        }
        .onChange(of: isFullBloom) { _, newValue in
            if newValue { startSparkle() }
        }
    }

    private func startSwayAnimation() {
        withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
            swayAngle = 4
        }
    }

    private func startSparkle() {
        withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
            sparkleOpacity = 1.0
        }
    }

    private func startAuraAnimation() {
        // 페이드 인
        withAnimation(.easeIn(duration: 0.5)) {
            auraOpacity = 1.0
        }

        // 오라 1 - 느린 펄스
        withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
            auraScale1 = 1.2
        }

        // 오라 2 - 중간 속도
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
            auraScale2 = 1.3
        }

        // 오라 3 - 빠른 펄스
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            auraScale3 = 1.4
        }
    }

    private func stopAuraAnimation() {
        withAnimation(.easeOut(duration: 0.5)) {
            auraOpacity = 0.0
            auraScale1 = 1.0
            auraScale2 = 1.0
            auraScale3 = 1.0
        }
    }
}

// MARK: - Shapes

struct Arc: Shape {
    var startAngle: Angle
    var endAngle: Angle
    var clockwise: Bool

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addArc(
            center: CGPoint(x: rect.midX, y: rect.midY),
            radius: rect.width / 2,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: clockwise
        )
        return path
    }
}

struct PetalShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        path.move(to: CGPoint(x: w / 2, y: h))
        path.addQuadCurve(
            to: CGPoint(x: w / 2, y: 0),
            control: CGPoint(x: -w * 0.2, y: h * 0.4)
        )
        path.addQuadCurve(
            to: CGPoint(x: w / 2, y: h),
            control: CGPoint(x: w * 1.2, y: h * 0.4)
        )
        return path
    }
}

#Preview {
    HStack(spacing: 12) {
        SunAnimationView(health: 10, isTracking: false)
        SunAnimationView(health: 50, isTracking: true)
        SunAnimationView(health: 100, isTracking: false)
    }
}

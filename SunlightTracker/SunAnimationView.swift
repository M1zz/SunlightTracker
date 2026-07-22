import SwiftUI

struct SunAnimationView: View {
    let health: Double  // 0~100
    let isTracking: Bool
    var petalColorState: PetalColorState = .defaultYellow
    var friendName: String? = nil   // 함께 받는 친구 (있으면 옆에 등장)
    @State private var swayAngle: Double = 0
    @State private var sparkleOpacity: Double = 0
    @State private var heartPulse = false
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

    // 로고 스타일 컬러 (귀여운 캐릭터)
    private let outlineColor = Color(red: 0.42, green: 0.26, blue: 0.13)  // 진갈색 테두리/눈/입
    private let blushColor = Color(red: 1.0, green: 0.5, blue: 0.4)       // 볼터치

    // 얼굴 색상 (시들면 어두워짐) - 로고처럼 밝은 노랑
    private var faceColor: Color {
        switch healthState {
        case .thriving: return Color(red: 1.0, green: 0.82, blue: 0.15)
        case .healthy: return Color(red: 0.97, green: 0.76, blue: 0.2)
        case .wilting: return Color(red: 0.8, green: 0.62, blue: 0.25)
        case .critical: return Color(red: 0.55, green: 0.44, blue: 0.24)
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

    // 뒷줄 꽃잎 색상 (앞줄보다 진한 주황 - 로고의 겹꽃잎 느낌)
    private var backPetalColor: LinearGradient {
        switch healthState {
        case .thriving:
            return LinearGradient(
                colors: [Color(red: 1.0, green: 0.65, blue: 0.05), Color(red: 0.95, green: 0.5, blue: 0.0)],
                startPoint: .top, endPoint: .bottom
            )
        case .healthy:
            return LinearGradient(
                colors: [Color(red: 0.95, green: 0.6, blue: 0.1), Color(red: 0.9, green: 0.45, blue: 0.05)],
                startPoint: .top, endPoint: .bottom
            )
        case .wilting:
            return LinearGradient(
                colors: [Color(red: 0.7, green: 0.5, blue: 0.15), Color(red: 0.6, green: 0.4, blue: 0.1)],
                startPoint: .top, endPoint: .bottom
            )
        case .critical:
            return LinearGradient(
                colors: [Color(red: 0.5, green: 0.33, blue: 0.15), Color(red: 0.4, green: 0.25, blue: 0.1)],
                startPoint: .top, endPoint: .bottom
            )
        }
    }

    // 꽃잎 외곽선 색상
    private var petalOutlineColor: Color {
        switch healthState {
        case .thriving, .healthy: return Color(red: 0.9, green: 0.5, blue: 0.05).opacity(0.7)
        case .wilting, .critical: return Color(red: 0.45, green: 0.3, blue: 0.1).opacity(0.7)
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
                // 뒷줄 꽃잎 (사이사이 채움, 진한 주황 - 겹꽃잎 느낌)
                ForEach(0..<12, id: \.self) { i in
                    PetalShape()
                        .fill(backPetalColor)
                        .frame(width: 15, height: 30)
                        .offset(y: -55)
                        .rotationEffect(.degrees(Double(i) * 30 + 15 + petalDroop))
                        .animation(.easeInOut(duration: 0.8), value: petalDroop)
                }

                // 앞줄 꽃잎 (12개, 외곽선으로 또렷하게)
                ForEach(0..<12, id: \.self) { i in
                    PetalShape()
                        .fill(petalGradient(for: i))
                        .overlay(PetalShape().stroke(petalOutlineColor, lineWidth: 1.2))
                        .frame(width: 17, height: 34)
                        .offset(y: -52)
                        .rotationEffect(.degrees(Double(i) * 30 + petalDroop))
                        .animation(.easeInOut(duration: 0.8), value: petalDroop)
                        .animation(.easeInOut(duration: 1.5), value: petalColorState.blendFactor)
                }

                // 얼굴 원 (밝은 노랑 + 진갈색 테두리 링)
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [faceColor.opacity(0.95), faceColor],
                            center: .init(x: 0.4, y: 0.35),
                            startRadius: 5,
                            endRadius: 45
                        )
                    )
                    .overlay(
                        Circle().strokeBorder(outlineColor, lineWidth: 4.5)
                    )
                    .frame(width: 80, height: 80)
                    .shadow(color: faceColor.opacity(0.4), radius: isTracking ? 12 : 6)

                // 윤광 하이라이트 (반질반질한 느낌)
                Ellipse()
                    .fill(Color.white.opacity(0.35))
                    .frame(width: 22, height: 12)
                    .rotationEffect(.degrees(-25))
                    .offset(x: -16, y: -20)

                // 볼터치 + 주근깨
                HStack(spacing: 42) {
                    cheekView
                    cheekView
                }
                .offset(y: 10)

                // 눈 + 입 + 썬글라스
                VStack(spacing: 6) {
                    ZStack {
                        // 기본 눈 (썬글라스 없을 때만 보임) - 까만 눈 + 반짝 하이라이트
                        if !isTracking {
                            HStack(spacing: 16) {
                                cuteEye
                                cuteEye
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
                        // 웃는 입 (진갈색, 둥근 끝)
                        Arc(startAngle: .degrees(0), endAngle: .degrees(180), clockwise: false)
                            .stroke(outlineColor, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                            .frame(width: 18, height: 9)
                    } else {
                        // 슬픈 입
                        Arc(startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
                            .stroke(outlineColor, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                            .frame(width: 14, height: 7)
                    }
                }
                .offset(y: -2)
                .animation(.easeInOut(duration: 0.5), value: healthState)
            }
            .rotationEffect(.degrees(isTracking ? swayAngle : 0))
            .offset(x: friendName != nil ? -28 : 0)  // 친구가 오면 살짝 비켜줌
            .animation(.spring(response: 0.6, dampingFraction: 0.75), value: friendName != nil)

            // 함께 받는 친구 등장!
            if let friendName {
                VStack(spacing: 4) {
                    FriendMiniFlowerView(isTracking: isTracking)
                        .frame(width: 80, height: 80)
                        .rotationEffect(.degrees(isTracking ? -swayAngle : 0))
                    Text(friendName)
                        .font(.caption2.weight(.bold))
                        .foregroundColor(Color(red: 0.42, green: 0.26, blue: 0.13))
                        .lineLimit(1)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(Color.white.opacity(0.75)))
                        .frame(maxWidth: 96)
                }
                .offset(x: 72, y: 42)
                .transition(.scale(scale: 0.2, anchor: .bottom).combined(with: .opacity))

                // 둘 사이 하트
                Text("\u{1F49B}")
                    .font(.system(size: 20))
                    .offset(x: 26, y: -6)
                    .scaleEffect(heartPulse ? 1.2 : 0.85)
                    .opacity(heartPulse ? 1.0 : 0.5)
                    .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: heartPulse)
                    .onAppear { heartPulse = true }
                    .onDisappear { heartPulse = false }
                    .transition(.scale.combined(with: .opacity))
            }

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

        }
        .frame(width: 240, height: 240)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .animation(.spring(response: 0.6, dampingFraction: 0.75), value: friendName)
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

    // 귀여운 눈 (진갈색 + 반짝 하이라이트)
    private var cuteEye: some View {
        ZStack {
            Circle()
                .fill(outlineColor)
                .frame(width: 9, height: 9)
            Circle()
                .fill(Color.white.opacity(0.9))
                .frame(width: 3, height: 3)
                .offset(x: -1.5, y: -1.5)
        }
    }

    // 볼터치 + 주근깨
    private var cheekView: some View {
        ZStack {
            Ellipse()
                .fill(blushColor.opacity(healthState == .critical ? 0.25 : 0.45))
                .frame(width: 13, height: 8)
            HStack(spacing: 2.5) {
                ForEach(0..<3, id: \.self) { _ in
                    Circle()
                        .fill(outlineColor.opacity(0.4))
                        .frame(width: 1.5, height: 1.5)
                }
            }
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

// MARK: - 함께 받는 친구 미니 해바라기
struct FriendMiniFlowerView: View {
    let isTracking: Bool
    private let outline = Color(red: 0.42, green: 0.26, blue: 0.13)

    var body: some View {
        ZStack {
            // 꽃잎 (친구는 살구빛으로 구분)
            ForEach(0..<10, id: \.self) { i in
                PetalShape()
                    .fill(
                        LinearGradient(
                            colors: [Color(red: 1.0, green: 0.65, blue: 0.35), Color(red: 1.0, green: 0.5, blue: 0.25)],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
                    .frame(width: 10, height: 19)
                    .offset(y: -27)
                    .rotationEffect(.degrees(Double(i) * 36))
            }

            // 얼굴
            Circle()
                .fill(Color(red: 1.0, green: 0.82, blue: 0.2))
                .overlay(Circle().strokeBorder(outline, lineWidth: 2.5))
                .frame(width: 40, height: 40)

            // 눈 + 입 (트래킹 중엔 같이 썬글라스)
            VStack(spacing: 3) {
                if isTracking {
                    HStack(spacing: 2) {
                        Ellipse().fill(Color.black.opacity(0.85)).frame(width: 8, height: 6)
                        Rectangle().fill(Color.black).frame(width: 2, height: 1.5)
                        Ellipse().fill(Color.black.opacity(0.85)).frame(width: 8, height: 6)
                    }
                } else {
                    HStack(spacing: 8) {
                        Circle().fill(outline).frame(width: 5, height: 5)
                        Circle().fill(outline).frame(width: 5, height: 5)
                    }
                }
                Arc(startAngle: .degrees(0), endAngle: .degrees(180), clockwise: false)
                    .stroke(outline, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                    .frame(width: 10, height: 5)
            }
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
        // 통통하고 끝이 뾰족한 꽃잎 (로고 스타일)
        path.move(to: CGPoint(x: w / 2, y: h))
        path.addQuadCurve(
            to: CGPoint(x: w / 2, y: 0),
            control: CGPoint(x: -w * 0.35, y: h * 0.45)
        )
        path.addQuadCurve(
            to: CGPoint(x: w / 2, y: h),
            control: CGPoint(x: w * 1.35, y: h * 0.45)
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

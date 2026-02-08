import SwiftUI

struct SunAnimationView: View {
    let progress: Double
    let isTracking: Bool
    @State private var swayAngle: Double = 0
    @State private var sparkleOpacity: Double = 0

    private var clampedProgress: Double { min(max(progress, 0), 1.0) }

    // 꽃잎 개수: progress에 비례 (0개 ~ 12개)
    private var petalCount: Int {
        Int(clampedProgress * 12)
    }

    // 꽃잎 크기
    private var petalLength: CGFloat {
        guard clampedProgress > 0 else { return 0 }
        return 12 + clampedProgress * 20
    }

    // 얼굴 색상
    private var faceColor: Color {
        if clampedProgress >= 1.0 { return .orange }
        if clampedProgress >= 0.5 { return Color(red: 1.0, green: 0.8, blue: 0.2) }
        return Color(red: 1.0, green: 0.9, blue: 0.4)
    }

    private var isFullBloom: Bool { clampedProgress >= 1.0 }

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

            // 해바라기 (얼굴 + 꽃잎)
            ZStack {
                // 꽃잎
                ForEach(0..<12, id: \.self) { i in
                    if i < petalCount {
                        PetalShape()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(red: 1.0, green: 0.85, blue: 0.1),
                                        Color(red: 1.0, green: 0.7, blue: 0.0)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(width: 16, height: petalLength)
                            .offset(y: -52)
                            .rotationEffect(.degrees(Double(i) * 30))
                            .transition(.scale.combined(with: .opacity))
                            .animation(.easeOut(duration: 0.5).delay(Double(i) * 0.04), value: petalCount)
                    }
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

                // 눈 + 입
                VStack(spacing: 6) {
                    HStack(spacing: 16) {
                        Circle().fill(Color.white).frame(width: 8, height: 8)
                        Circle().fill(Color.white).frame(width: 8, height: 8)
                    }

                    if isFullBloom {
                        // 활짝 웃는 입
                        Arc(startAngle: .degrees(0), endAngle: .degrees(180), clockwise: false)
                            .stroke(Color.white, lineWidth: 2.5)
                            .frame(width: 22, height: 11)
                    } else {
                        // 살짝 미소
                        Arc(startAngle: .degrees(0), endAngle: .degrees(180), clockwise: false)
                            .stroke(Color.white, lineWidth: 2)
                            .frame(width: 16, height: 8)
                    }
                }
                .offset(y: -2)

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

            // 진행률 텍스트
            VStack {
                Spacer()
                Text("\(Int(clampedProgress * 100))%")
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
            if isTracking { startSwayAnimation() }
            if isFullBloom { startSparkle() }
        }
        .onChange(of: isTracking) { _, newValue in
            if newValue {
                startSwayAnimation()
            } else {
                withAnimation(.easeOut(duration: 0.5)) { swayAngle = 0 }
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
        SunAnimationView(progress: 0.0, isTracking: false)
        SunAnimationView(progress: 0.5, isTracking: true)
        SunAnimationView(progress: 1.0, isTracking: false)
    }
}

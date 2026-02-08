import SwiftUI

struct SunAnimationView: View {
    let progress: Double
    let isTracking: Bool
    @State private var swayAngle: Double = 0
    @State private var sparkleOpacity: Double = 0
    @State private var petalScale: CGFloat = 0

    // 성장 단계 (0~1)
    private var stemHeight: CGFloat {
        if progress < 0.05 { return 0 }
        return min(CGFloat(progress) * 1.2, 1.0) * 120
    }

    private var petalCount: Int {
        if progress < 0.6 { return 0 }
        if progress < 0.7 { return 4 }
        if progress < 0.8 { return 8 }
        return 12
    }

    private var petalOpenness: CGFloat {
        guard progress >= 0.6 else { return 0 }
        return min(CGFloat((progress - 0.6) / 0.4), 1.0)
    }

    private var showSeed: Bool { progress < 0.05 }
    private var showSprout: Bool { progress >= 0.05 && progress < 0.2 }
    private var showLeaves: Bool { progress >= 0.2 }
    private var showBud: Bool { progress >= 0.4 }
    private var showPetals: Bool { progress >= 0.6 }
    private var isFullBloom: Bool { progress >= 0.8 }

    var body: some View {
        ZStack {
            // 하늘 배경
            skyBackground

            // 잔디
            grassLayer

            // 해바라기
            sunflowerPlant
                .rotationEffect(.degrees(isTracking ? swayAngle : 0), anchor: .bottom)

            // 만개 시 반짝이 이펙트
            if isFullBloom {
                sparkleEffects
            }

            // 진행률 텍스트
            VStack {
                Spacer()
                Text("\(Int(min(progress, 1.0) * 100))%")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Color.black.opacity(0.25))
                    .cornerRadius(12)
                    .padding(.bottom, 8)
            }
        }
        .frame(width: 260, height: 280)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .onAppear {
            if isTracking {
                startSwayAnimation()
            }
            withAnimation(.easeOut(duration: 0.8)) {
                petalScale = 1.0
            }
        }
        .onChange(of: isTracking) { _, newValue in
            if newValue {
                startSwayAnimation()
            } else {
                withAnimation(.easeOut(duration: 0.5)) {
                    swayAngle = 0
                }
            }
        }
        .onChange(of: progress) { _, _ in
            if isFullBloom {
                withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                    sparkleOpacity = 1.0
                }
            }
        }
    }

    // MARK: - Sky Background
    private var skyBackground: some View {
        LinearGradient(
            colors: [
                Color(red: 0.53, green: 0.81, blue: 0.98),
                Color(red: 0.68, green: 0.88, blue: 1.0),
                Color(red: 0.85, green: 0.94, blue: 1.0)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    // MARK: - Grass
    private var grassLayer: some View {
        VStack {
            Spacer()
            ZStack {
                // 잔디 배경
                Ellipse()
                    .fill(
                        LinearGradient(
                            colors: [Color(red: 0.3, green: 0.7, blue: 0.2), Color(red: 0.2, green: 0.55, blue: 0.15)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 300, height: 80)
                    .offset(y: 20)

                // 흙
                Ellipse()
                    .fill(Color(red: 0.55, green: 0.35, blue: 0.2))
                    .frame(width: 60, height: 20)
                    .offset(y: 10)
            }
        }
    }

    // MARK: - Sunflower Plant
    private var sunflowerPlant: some View {
        VStack(spacing: 0) {
            Spacer()

            if showSeed {
                // 씨앗
                seedView
            } else {
                ZStack(alignment: .bottom) {
                    // 줄기
                    stemView

                    // 잎
                    if showLeaves {
                        leavesView
                    }

                    // 꽃 머리 (봉오리 또는 개화)
                    if showBud {
                        flowerHead
                            .offset(y: -stemHeight - 10)
                    }

                    // 새싹 떡잎
                    if showSprout && !showLeaves {
                        sproutView
                    }
                }
            }
        }
        .padding(.bottom, 35)
    }

    // MARK: - Seed
    private var seedView: some View {
        Ellipse()
            .fill(
                LinearGradient(
                    colors: [Color(red: 0.45, green: 0.3, blue: 0.15), Color(red: 0.35, green: 0.22, blue: 0.1)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: 12, height: 8)
            .shadow(color: .black.opacity(0.2), radius: 2, y: 1)
    }

    // MARK: - Sprout
    private var sproutView: some View {
        ZStack(alignment: .bottom) {
            // 작은 줄기
            Rectangle()
                .fill(Color(red: 0.3, green: 0.65, blue: 0.2))
                .frame(width: 3, height: stemHeight)

            // 떡잎 2개
            HStack(spacing: 0) {
                // 왼쪽 떡잎
                Ellipse()
                    .fill(Color(red: 0.4, green: 0.75, blue: 0.25))
                    .frame(width: 14, height: 8)
                    .rotationEffect(.degrees(-30))
                    .offset(x: -6)

                // 오른쪽 떡잎
                Ellipse()
                    .fill(Color(red: 0.4, green: 0.75, blue: 0.25))
                    .frame(width: 14, height: 8)
                    .rotationEffect(.degrees(30))
                    .offset(x: 6)
            }
            .offset(y: -stemHeight + 4)
        }
    }

    // MARK: - Stem
    private var stemView: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [Color(red: 0.3, green: 0.65, blue: 0.2), Color(red: 0.25, green: 0.55, blue: 0.15)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: 5, height: stemHeight)
    }

    // MARK: - Leaves
    private var leavesView: some View {
        ZStack(alignment: .bottom) {
            // 왼쪽 잎
            SunflowerLeaf()
                .fill(Color(red: 0.3, green: 0.7, blue: 0.2))
                .frame(width: 30, height: 18)
                .rotationEffect(.degrees(-25))
                .offset(x: -18, y: -stemHeight * 0.35)

            // 오른쪽 잎
            SunflowerLeaf()
                .fill(Color(red: 0.35, green: 0.72, blue: 0.22))
                .frame(width: 30, height: 18)
                .scaleEffect(x: -1, y: 1)
                .rotationEffect(.degrees(25))
                .offset(x: 18, y: -stemHeight * 0.55)

            // 추가 잎 (줄기가 클 때)
            if progress >= 0.4 {
                SunflowerLeaf()
                    .fill(Color(red: 0.32, green: 0.68, blue: 0.2))
                    .frame(width: 25, height: 15)
                    .rotationEffect(.degrees(-20))
                    .offset(x: -15, y: -stemHeight * 0.7)
            }
        }
    }

    // MARK: - Flower Head
    private var flowerHead: some View {
        ZStack {
            if showPetals {
                // 꽃잎들
                ForEach(0..<petalCount, id: \.self) { i in
                    let angle = Double(i) * (360.0 / Double(petalCount))
                    PetalShape()
                        .fill(
                            LinearGradient(
                                colors: [Color(red: 1.0, green: 0.85, blue: 0.1), Color(red: 1.0, green: 0.7, blue: 0.0)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 14, height: isFullBloom ? 28 : 20)
                        .offset(y: isFullBloom ? -24 : -18)
                        .rotationEffect(.degrees(angle))
                        .scaleEffect(petalOpenness)
                        .animation(.easeOut(duration: 0.6).delay(Double(i) * 0.05), value: petalOpenness)
                }
            }

            // 중심부 (씨앗 패턴)
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(red: 0.45, green: 0.25, blue: 0.1),
                            Color(red: 0.35, green: 0.2, blue: 0.05),
                            Color(red: 0.55, green: 0.35, blue: 0.15)
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: isFullBloom ? 16 : 10
                    )
                )
                .frame(width: isFullBloom ? 32 : 20, height: isFullBloom ? 32 : 20)
                .overlay(
                    // 씨앗 패턴 (만개 시)
                    isFullBloom ? AnyView(seedPattern) : AnyView(EmptyView())
                )

            // 꽃봉오리 (아직 안 핀 경우)
            if !showPetals {
                budView
            }
        }
    }

    // MARK: - Bud
    private var budView: some View {
        ZStack {
            // 꽃받침
            ForEach(0..<3, id: \.self) { i in
                let angle = -30.0 + Double(i) * 30.0
                Ellipse()
                    .fill(Color(red: 0.3, green: 0.6, blue: 0.2))
                    .frame(width: 10, height: 16)
                    .offset(y: -8)
                    .rotationEffect(.degrees(angle))
            }
        }
    }

    // MARK: - Seed Pattern (만개 시)
    private var seedPattern: some View {
        ZStack {
            ForEach(0..<5, id: \.self) { ring in
                ForEach(0..<max(1, ring * 4), id: \.self) { dot in
                    let angle = Double(dot) * (360.0 / Double(max(1, ring * 4)))
                    let radius = CGFloat(ring) * 3.0
                    Circle()
                        .fill(Color(red: 0.3, green: 0.18, blue: 0.05).opacity(0.6))
                        .frame(width: 1.5, height: 1.5)
                        .offset(
                            x: radius * cos(angle * .pi / 180),
                            y: radius * sin(angle * .pi / 180)
                        )
                }
            }
        }
    }

    // MARK: - Sparkle Effects
    private var sparkleEffects: some View {
        ZStack {
            ForEach(0..<6, id: \.self) { i in
                let positions: [(CGFloat, CGFloat)] = [
                    (-40, -80), (50, -60), (-60, -40),
                    (30, -100), (-20, -120), (60, -90)
                ]
                Image(systemName: "sparkle")
                    .font(.system(size: CGFloat.random(in: 8...14)))
                    .foregroundColor(.yellow.opacity(sparkleOpacity * Double.random(in: 0.4...1.0)))
                    .offset(x: positions[i].0, y: positions[i].1)
            }
        }
    }

    // MARK: - Animation Helpers
    private func startSwayAnimation() {
        withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
            swayAngle = 3
        }
    }
}

// MARK: - Custom Shapes

struct SunflowerLeaf: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        path.move(to: CGPoint(x: 0, y: h / 2))
        path.addQuadCurve(
            to: CGPoint(x: w, y: h / 2),
            control: CGPoint(x: w * 0.5, y: -h * 0.3)
        )
        path.addQuadCurve(
            to: CGPoint(x: 0, y: h / 2),
            control: CGPoint(x: w * 0.5, y: h * 1.3)
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
    VStack(spacing: 20) {
        HStack(spacing: 10) {
            SunAnimationView(progress: 0.0, isTracking: false)
                .frame(width: 160, height: 180)
            SunAnimationView(progress: 0.15, isTracking: false)
                .frame(width: 160, height: 180)
        }
        HStack(spacing: 10) {
            SunAnimationView(progress: 0.5, isTracking: true)
                .frame(width: 160, height: 180)
            SunAnimationView(progress: 0.75, isTracking: true)
                .frame(width: 160, height: 180)
        }
        SunAnimationView(progress: 1.0, isTracking: false)
    }
}

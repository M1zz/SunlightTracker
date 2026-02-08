import SwiftUI

struct SunAnimationView: View {
    let progress: Double
    let isTracking: Bool
    @State private var animateRays = false
    @State private var pulseScale: CGFloat = 1.0
    
    private var sunColor: Color {
        if progress >= 1.0 {
            return .orange
        } else if progress >= 0.5 {
            return Color(red: 1.0, green: 0.8, blue: 0.2)
        } else {
            return Color(red: 1.0, green: 0.9, blue: 0.4)
        }
    }
    
    private var backgroundColor: [Color] {
        if progress >= 1.0 {
            return [Color.orange.opacity(0.15), Color.yellow.opacity(0.05)]
        } else {
            return [Color.yellow.opacity(0.1), Color.clear]
        }
    }
    
    var body: some View {
        ZStack {
            // Background glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: backgroundColor,
                        center: .center,
                        startRadius: 40,
                        endRadius: 120
                    )
                )
                .frame(width: 240, height: 240)
            
            // Sun rays
            ForEach(0..<12, id: \.self) { index in
                let angle = Double(index) * 30
                let rayProgress = min(progress * 1.2, 1.0)
                
                RoundedRectangle(cornerRadius: 2)
                    .fill(sunColor.opacity(0.4 * rayProgress))
                    .frame(width: 3, height: 20 + (animateRays ? 8 : 0))
                    .offset(y: -75)
                    .rotationEffect(.degrees(angle))
                    .opacity(Double(index) / 12.0 <= progress ? 1.0 : 0.15)
            }
            
            // Progress ring background
            Circle()
                .stroke(Color.gray.opacity(0.15), lineWidth: 12)
                .frame(width: 140, height: 140)
            
            // Progress ring
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    AngularGradient(
                        colors: [sunColor.opacity(0.6), sunColor],
                        center: .center,
                        startAngle: .degrees(0),
                        endAngle: .degrees(360 * progress)
                    ),
                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                )
                .frame(width: 140, height: 140)
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 1.0), value: progress)
            
            // Center sun face
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [sunColor, sunColor.opacity(0.8)],
                            center: .center,
                            startRadius: 10,
                            endRadius: 45
                        )
                    )
                    .frame(width: 90, height: 90)
                    .scaleEffect(pulseScale)
                    .shadow(color: sunColor.opacity(0.4), radius: isTracking ? 15 : 8)
                
                // Face
                VStack(spacing: 4) {
                    // Eyes
                    HStack(spacing: 16) {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 8, height: 8)
                        Circle()
                            .fill(Color.white)
                            .frame(width: 8, height: 8)
                    }
                    
                    // Mouth
                    if progress >= 1.0 {
                        // Happy
                        Text("😊")
                            .font(.system(size: 14))
                    } else {
                        // Slight smile
                        Arc(startAngle: .degrees(0), endAngle: .degrees(180), clockwise: false)
                            .stroke(Color.white, lineWidth: 2)
                            .frame(width: 16, height: 8)
                    }
                }
                .offset(y: -2)
            }
            
            // Percentage text
            VStack(spacing: 2) {
                Spacer()
                Text("\(Int(progress * 100))%")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(sunColor)
            }
            .frame(height: 200)
        }
        .frame(width: 240, height: 240)
        .onAppear {
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                animateRays = true
            }
            if isTracking {
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    pulseScale = 1.08
                }
            }
        }
        .onChange(of: isTracking) { _, newValue in
            if newValue {
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    pulseScale = 1.08
                }
            } else {
                withAnimation(.easeInOut(duration: 0.3)) {
                    pulseScale = 1.0
                }
            }
        }
    }
}

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

#Preview {
    VStack(spacing: 40) {
        SunAnimationView(progress: 0.3, isTracking: false)
        SunAnimationView(progress: 0.75, isTracking: true)
        SunAnimationView(progress: 1.0, isTracking: false)
    }
}

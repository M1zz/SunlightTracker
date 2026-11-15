import SwiftUI
import LeeoKit

struct DashboardView: View {
    @ObservedObject var manager: SunlightManager
    @ObservedObject var weatherService: WeatherService
    @ObservedObject private var pro = SunflowerPro.shared
    @State private var showManualEntry = false
    @State private var manualMinutes: Double = 15
    @State private var hasAutoStarted = false

    /// 스토어 스크린샷용: Debug 빌드에서만 `-ScreenshotIdle YES` 로 열자마자 감지를 시작하지 않는다(대기 화면을 찍는다).
    private static var screenshotIdle: Bool {
        #if DEBUG
        return UserDefaults.standard.bool(forKey: "ScreenshotIdle")
        #else
        return false
        #endif
    }
    @State private var sensingPulse = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// 큰 숫자도 글자 크기 설정을 따라 커지게
    @ScaledMetric(relativeTo: .largeTitle) private var bigNumberSize: CGFloat = 48

    private var currentSessionMinutes: Int {
        guard let session = manager.currentSession else { return 0 }
        return max(Int(Date().timeIntervalSince(session.startTime) / 60), 0)
    }

    private var displayMinutes: Int {
        if manager.isConfirmedOutdoor {
            return manager.todayRecord.totalMinutes + manager.confirmedElapsedMinutes
        }
        return manager.todayRecord.totalMinutes + (manager.isSunlightDetected ? currentSessionMinutes : 0)
    }

    private var displayProgress: Double {
        guard manager.todayRecord.goalMinutes > 0 else { return 0 }
        return min(Double(displayMinutes) / Double(manager.todayRecord.goalMinutes), 1.0)
    }

    var body: some View {
        NavigationStack {
        ScrollView {
            VStack(spacing: 16) {
                // 햇빛 배터리 (히어로)
                sunGauge

                // 함께 트래킹 배지
                if manager.nearbyManager.isSharedActivityActive {
                    NearbyActivityBadge(
                        friendName: manager.nearbyManager.connectedPeerNames.first,
                        peerCount: manager.nearbyManager.connectedPeerCount,
                        distance: manager.nearbyManager.nearbyPeerDistance
                    )
                }

                // 오늘 햇빛 진행도 (컴팩트)
                todayProgressCard

                // 목표를 채운 날이 쌓였을 때만, 드물게 응원을 부탁한다. 햇빛을 재는 동안에는 묻지 않는다 (모달 아님)
                // 응원 부탁은 이미 Pro 를 가진 사람에게만 — 무료로 쓰는 사람에게 돈 이야기를 두 번 하지 않는다.
                if manager.trackingPhase == .idle, pro.hasPro {
                    LeeoTipAskSlot<SunlightTrackerSpec>(tipJar: SunlightTrackerSpec.tipJar,
                                                        reached: SunlightTipMoments.reached(goalDays: manager.weeklyRecords.filter(\.goalAchieved).count))
                }

                // 트래킹: 진행 중 카드 or 시작 버튼
                if manager.trackingPhase == .confirmed {
                    trackingCard
                } else {
                    trackingButton
                    if manager.trackingPhase == .detecting {
                        compactLuxCard
                    }
                }

                // 수동 입력 (보조 액션)
                manualEntryButton
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 30)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(AppConfig.appName)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            weatherService.fetchSimulatedWeather()
            manager.requestLocation()
            // 센서는 SunlightManager init에서 자동 시작됨
            // 트래킹(햇빛 감지)은 사용자가 시작하거나 자동 감지로 전환
            if !hasAutoStarted && manager.trackingPhase == .idle && !Self.screenshotIdle {
                manager.startTracking()
                hasAutoStarted = true
            }
            // 확인 후 트래킹 중이면 화면 진입 시 즉시 재측정
            manager.refreshLuxReading()
        }
        .sheet(isPresented: $showManualEntry) {
            manualEntrySheet
        }
        // 처음 만나는 친구와 함께 받기 전 확인
        .alert(
            "\u{1F33B} \(manager.nearbyManager.pendingFriendRequest ?? String(localized: "친구"))이(가) 옆에서 햇빛을 받고 있어요!",
            isPresented: Binding(
                get: { manager.nearbyManager.pendingFriendRequest != nil },
                set: { if !$0 { manager.nearbyManager.declinePendingFriend() } }
            )
        ) {
            Button("같이 받기 \u{1F49B}") { manager.nearbyManager.approvePendingFriend() }
            Button("다음에", role: .cancel) { manager.nearbyManager.declinePendingFriend() }
        } message: {
            Text("같이 받으면 꽃잎이 알록달록 물들고, 친구 탭에 함께한 기록이 남아요.")
        }
        } // NavigationStack
    }

    // MARK: - 조도 배터리 게이지
    private var displayLux: Double {
        manager.isConfirmedOutdoor ? manager.lastKnownLux : manager.luxSensor.currentLux
    }

    private var displayLightLevel: String {
        if manager.isConfirmedOutdoor {
            if manager.lastKnownLux >= 10000 { return String(localized: "강한 햇빛") }
            if manager.lastKnownLux >= 1000 { return String(localized: "햇빛") }
            return String(localized: "실외")
        }
        return String(localized: String.LocalizationValue(manager.luxSensor.lightLevel.rawValue))
    }

    private var batteryColor: Color {
        if displayLux >= manager.settings.outdoorThresholdLux { return Color(red: 0.3, green: 0.7, blue: 0.2) }
        if displayLux >= 50 { return .orange }
        return .gray
    }

    private var luxEmoji: String {
        switch displayLux {
        case ..<50: return "\u{1F319}"
        case 50..<300: return "\u{1F4A1}"
        case 300..<1000: return "\u{26C5}"
        case 1000..<10000: return "\u{2600}\u{FE0F}"
        default: return "\u{1F506}"
        }
    }

    // 지금 밝기 카드 (감지 중)
    private var compactLuxCard: some View {
        HStack(spacing: 10) {
            Text(luxEmoji)
                .font(.title3)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(displayLightLevel)
                    .font(.subheadline.weight(.bold))
                    .foregroundColor(batteryColor)
                Text("\(displayLux.luxFormatted) Lux")
                    .font(.system(.caption, design: .rounded))
                    .foregroundColor(.secondary)
            }
            Spacer()
            sensingBadge
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(RoundedRectangle(cornerRadius: 20).fill(Color(.secondarySystemGroupedBackground)))
        .accessibilityElement(children: .combine)
    }

    // 측정 상태 배지 (측정 중 펄스 / 쉬는 중)
    private var sensingBadge: some View {
        Group {
            if manager.luxSensor.isActive {
                HStack(spacing: 5) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 7, height: 7)
                        .opacity(sensingPulse ? 1.0 : 0.3)
                        .animation(reduceMotion ? nil : .easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: sensingPulse)
                        .onAppear { sensingPulse = true }
                        .onDisappear { sensingPulse = false }
                    Text("측정 중")
                        .font(.caption2.weight(.semibold))
                        .foregroundColor(.green)
                }
            } else {
                Text("잠시 쉬는 중 \u{1F4A4}")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }

    // MARK: - 오늘 햇빛 진행도 (컴팩트)
    private var todayProgressCard: some View {
        VStack(spacing: 10) {
            HStack {
                Text("\u{2600}\u{FE0F} 오늘의 햇빛")
                    .font(.subheadline.weight(.bold))
                Spacer()
                if displayProgress >= 1.0 {
                    Text("목표 달성! \u{1F389}")
                        .font(.system(.subheadline, design: .rounded).weight(.bold))
                        .foregroundColor(.green)
                } else {
                    Text("\(displayMinutes) / \(manager.settings.dailyGoalMinutes)분")
                        .font(.system(.subheadline, design: .rounded).weight(.bold))
                        .foregroundColor(.orange)
                }
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.orange.opacity(0.12))
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: displayProgress >= 1.0 ?
                                    [Color(red: 0.4, green: 0.75, blue: 0.25), .green] :
                                    [.yellow, .orange],
                                startPoint: .leading, endPoint: .trailing
                            )
                        )
                        .frame(width: max(12, geo.size.width * displayProgress))
                        .animation(.easeInOut(duration: 0.8), value: displayProgress)
                }
            }
            .frame(height: 12)
            .accessibilityHidden(true)

            if let fromWatch = manager.todayRecord.healthMinutes, fromWatch > 0 {
                Label("Apple Watch에서 \(fromWatch)분", systemImage: "applewatch")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 20).fill(Color(.secondarySystemGroupedBackground)))
        .accessibilityElement(children: .combine)
    }

    // MARK: - 트래킹 진행 중 카드
    private var trackingCard: some View {
        VStack(spacing: 14) {
            HStack(spacing: 8) {
                Circle()
                    .fill(Color.green)
                    .frame(width: 10, height: 10)
                    .modifier(PulseModifier())
                Text("햇빛 받는 중 \u{1F31E}")
                    .font(.headline)
                    .foregroundColor(Color(red: 0.3, green: 0.65, blue: 0.2))
                Spacer()
                Text("\(manager.confirmedElapsedMinutes)분")
                    .font(.system(.title3, design: .rounded).weight(.bold))
            }
            .accessibilityElement(children: .combine)

            HStack {
                HStack(spacing: 6) {
                    Text(luxEmoji)
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(displayLightLevel)
                            .font(.caption.weight(.semibold))
                        Text("\(displayLux.luxFormatted) Lux")
                            .font(.system(.caption2, design: .rounded))
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()
                sensingBadge
                Spacer()
                HStack(spacing: 4) {
                    Text("\u{26A1}")
                    Text("+\(Int(manager.estimatedBatteryGain))%")
                        .font(.system(.subheadline, design: .rounded).weight(.bold))
                        .foregroundColor(.green)
                }
            }
            .padding(12)
            .background(RoundedRectangle(cornerRadius: 14).fill(Color.green.opacity(0.08)))
            .accessibilityElement(children: .combine)

            Button(action: {
                withAnimation(.spring(duration: 0.3)) { manager.finishTracking() }
            }) {
                Text("오늘은 그만 받기")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Capsule().fill(Color(red: 0.3, green: 0.7, blue: 0.2)))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.secondarySystemGroupedBackground))
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.green.opacity(0.35), lineWidth: 1.5))
        )
    }

    // MARK: - 햇빛 배터리
    /// 밖에 있는 동안은 지금까지 받은 만큼 미리 채워 보인다.
    private var liveEnergy: Double {
        let base = manager.sunflowerHealth.currentEnergy
        return manager.isConfirmedOutdoor ? min(100, base + manager.estimatedBatteryGain) : base
    }

    private var sunGauge: some View {
        SunGaugeView(
            level: liveEnergy,
            hoursLeft: liveEnergy / max(manager.sunflowerHealth.decayRatePerHour, 0.1),
            isCharging: manager.isConfirmedOutdoor,
            petals: manager.petalColorState
        )
        .padding(.top, 8)
    }

    // MARK: - Tracking Button (감지 or 대기 상태)
    private var trackingButton: some View {
        Button(action: {
            if manager.trackingPhase == .detecting {
                manager.cancelDetecting()
            } else {
                manager.startTracking()
            }
        }) {
            HStack(spacing: 10) {
                if manager.trackingPhase == .detecting {
                    Circle()
                        .fill(Color.white.opacity(0.7))
                        .frame(width: 10, height: 10)
                        .modifier(PulseModifier())
                    Text("햇빛 찾는 중... 탭하면 중지")
                        .font(.headline)
                } else {
                    Text("\u{2600}\u{FE0F}")
                        .font(.title3)
                        .accessibilityHidden(true)
                    Text("햇빛 받으러 가기")
                        .font(.headline)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .foregroundColor(.white)
            .background(
                Capsule()
                    .fill(manager.trackingPhase == .detecting ?
                          LinearGradient(colors: [.blue, .cyan], startPoint: .leading, endPoint: .trailing) :
                          LinearGradient(colors: [.orange, Color(red: 1.0, green: 0.75, blue: 0.1)], startPoint: .leading, endPoint: .trailing)
                    )
            )
            .shadow(color: (manager.trackingPhase == .detecting ? Color.blue : Color.orange).opacity(0.3), radius: 8, y: 4)
        }
    }

    // MARK: - Manual Entry
    private var manualEntryButton: some View {
        Button(action: { showManualEntry = true }) {
            HStack(spacing: 6) {
                Image(systemName: "plus.circle.fill")
                    .font(.footnote)
                    .accessibilityHidden(true)
                Text("야외 시간 직접 추가")
                    .font(.footnote.weight(.medium))
            }
            .foregroundColor(.secondary)
            .padding(.vertical, 8)
        }
    }

    private var manualEntrySheet: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("야외 활동 시간을 수동으로 추가합니다")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)

                VStack(spacing: 8) {
                    Text("\(Int(manualMinutes))분")
                        .font(.system(size: bigNumberSize, weight: .bold, design: .rounded))
                        .foregroundColor(.orange)
                        .accessibilityHidden(true)

                    Slider(value: $manualMinutes, in: 5...120, step: 5)
                        .tint(.orange)
                        .accessibilityLabel(Text("수동 입력"))
                        .accessibilityValue(Text("\(Int(manualMinutes))분"))

                    HStack {
                        Text("5분").font(.caption2).foregroundColor(.secondary)
                        Spacer()
                        Text("120분").font(.caption2).foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal)

                Button(action: {
                    manager.addManualSession(minutes: Int(manualMinutes))
                    showManualEntry = false
                }) {
                    Text("추가하기")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.orange)
                        .cornerRadius(12)
                }
                .padding(.horizontal)

                Spacer()
            }
            .padding(.top, 20)
            .navigationTitle("수동 입력")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { showManualEntry = false } label: { Label("취소", systemImage: "xmark") }
                }
            }
        }
        .presentationDetents([.medium])
    }

}

// MARK: - Pulse Modifier
struct PulseModifier: ViewModifier {
    @State private var isPulsing = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .scaleEffect(isPulsing && !reduceMotion ? 1.3 : 1.0)
            .opacity(isPulsing && !reduceMotion ? 0.5 : 1.0)
            .animation(reduceMotion ? nil : .easeInOut(duration: 1).repeatForever(autoreverses: true), value: isPulsing)
            .onAppear { isPulsing = true }
    }
}

// MARK: - Nearby Activity Badge
struct NearbyActivityBadge: View {
    var friendName: String? = nil
    let peerCount: Int
    let distance: Float?

    private var title: String {
        if let friendName, peerCount <= 1 {
            return String(localized: "\(friendName)이(가) 옆에서 같이 받는 중!")
        }
        return String(localized: "\(peerCount)명이랑 같이 받는 중!")
    }

    var body: some View {
        HStack(spacing: 10) {
            Text("\u{1F33B}\u{1F49B}\u{1F33B}")
                .font(.subheadline)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.bold))
                    .foregroundColor(Color(red: 0.85, green: 0.5, blue: 0.1))
                if let dist = distance {
                    Text("바로 옆 \(dist, specifier: "%.1f")m \u{1F31E}")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            Circle()
                .fill(Color.orange)
                .frame(width: 9, height: 9)
                .modifier(PulseModifier())
                .accessibilityHidden(true)
        }
        .accessibilityElement(children: .combine)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.yellow.opacity(0.18))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.orange.opacity(0.35), lineWidth: 1.5)
                )
        )
        .transition(.scale.combined(with: .opacity))
    }
}

// MARK: - Color Extension
extension Color {
    init?(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            return nil
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

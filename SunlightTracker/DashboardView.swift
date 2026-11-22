import SwiftUI
import LeeoKit

struct DashboardView: View {
    @ObservedObject var manager: SunlightManager
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
            VStack(spacing: 20) {
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

                // 오늘 밖에 있던 시간
                todayCard

                // 목표를 채운 날이 쌓였을 때만, 드물게 응원을 부탁한다. 햇빛을 재는 동안에는 묻지 않는다 (모달 아님)
                // 응원 부탁은 이미 Pro 를 가진 사람에게만 — 무료로 쓰는 사람에게 돈 이야기를 두 번 하지 않는다.
                if manager.trackingPhase == .idle, pro.hasPro {
                    LeeoTipAskSlot<SunlightTrackerSpec>(tipJar: SunlightTrackerSpec.tipJar,
                                                        reached: SunlightTipMoments.reached(goalDays: manager.weeklyRecords.filter(\.goalAchieved).count))
                }

                // 하나의 큰 버튼: 나가기 · 찾는 중 · 그만 받기
                actionButton

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
            Text("같이 받으면 햇살이 알록달록 물들고, 친구 탭에 함께한 기록이 남아요.")
        }
        } // NavigationStack
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

    // MARK: - 오늘 밖에 있던 시간 (글자 없이 숫자와 막대로)
    private var todayCard: some View {
        let done = displayProgress >= 1.0
        return VStack(spacing: 14) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Image(systemName: done ? "checkmark.circle.fill" : "figure.walk")
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundStyle(done ? .green : SunPalette.skyTop)
                    .accessibilityHidden(true)
                Text(verbatim: "\(displayMinutes)")
                    .font(.system(size: bigNumberSize * 1.2, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .contentTransition(.numericText())
                (Text(verbatim: "/ ") + Text("\(manager.settings.dailyGoalMinutes)분"))
                    .font(.system(.title2, design: .rounded).weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                if let fromWatch = manager.todayRecord.healthMinutes, fromWatch > 0 {
                    Label { Text(verbatim: "\(fromWatch)") } icon: { Image(systemName: "applewatch") }
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(SunPalette.skyTop.opacity(0.12))
                    Capsule()
                        .fill(done ? AnyShapeStyle(Color.green) : AnyShapeStyle(SunPalette.sky))
                        .frame(width: max(20, geo.size.width * displayProgress))
                        .animation(.easeInOut(duration: 0.8), value: displayProgress)
                }
            }
            .frame(height: 20)
            .accessibilityHidden(true)
        }
        .padding(20)
        .background(RoundedRectangle(cornerRadius: 28, style: .continuous).fill(Color(.secondarySystemGroupedBackground)))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("오늘의 햇빛"))
        .accessibilityValue(Text("\(displayMinutes) / \(manager.settings.dailyGoalMinutes)분"))
    }

    // MARK: - 큰 버튼 하나: 나가기 → 찾는 중 → 받는 중(그만 받기)
    private var actionButton: some View {
        let phase = manager.trackingPhase
        let icon: String
        let title: LocalizedStringKey
        let colors: [Color]
        switch phase {
        case .confirmed:
            icon = "stop.fill"; title = "오늘은 그만 받기"
            colors = [Color(red: 0.25, green: 0.65, blue: 0.3), .green]
        case .detecting:
            icon = "sun.max.fill"; title = "햇빛 찾는 중"
            colors = [SunPalette.skyTop, SunPalette.skyBottom]
        default:
            icon = "sun.max.fill"; title = "햇빛 받으러 가기"
            colors = [.orange, Color(red: 1.0, green: 0.75, blue: 0.1)]
        }
        return Button {
            withAnimation(.spring(duration: 0.3)) {
                switch phase {
                case .confirmed: manager.finishTracking()
                case .detecting: manager.cancelDetecting()
                default: manager.startTracking()
                }
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title.weight(.bold))
                    .symbolEffect(.pulse, isActive: phase == .detecting && !reduceMotion)
                    .accessibilityHidden(true)
                Text(title)
                    .font(.title2.weight(.bold))
            }
            .frame(maxWidth: .infinity, minHeight: 72)
            .foregroundStyle(.white)
            .background(Capsule().fill(LinearGradient(colors: colors, startPoint: .leading, endPoint: .trailing)))
            .shadow(color: colors[0].opacity(0.3), radius: 10, y: 5)
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
        return String(localized: "\(peerCount)명이랑 같이 받는 중!", locale: AppLocale.locale)
    }

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "person.2.fill")
                .font(.subheadline)
                .foregroundStyle(.orange)
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

import SwiftUI

struct DashboardView: View {
    @ObservedObject var manager: SunlightManager
    @ObservedObject var weatherService: WeatherService
    @State private var showManualEntry = false
    @State private var manualMinutes: Double = 15
    @State private var hasAutoStarted = false
    @State private var showBatteryTransfer = false
    @State private var transferAmount: Double = 0
    @State private var transferMax: Double = 1   // 시트 오픈 시점 스냅샷 (라이브 변경으로 인한 Slider 범위 붕괴 방지)
    @State private var sensingPulse = false

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
                // 해바라기 (히어로)
                sunProgressSection

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

                // 트래킹: 진행 중 카드 or 시작 버튼
                if manager.trackingPhase == .confirmed {
                    trackingCard
                } else {
                    trackingButton
                    if manager.trackingPhase == .detecting {
                        compactLuxCard
                    }
                }

                // 배터리 (전달 버튼 내장)
                batteryCard

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
            // 앱 시작 시 자동으로 조도 센서 시작
            if !hasAutoStarted && manager.trackingPhase == .idle {
                manager.startTracking()
                hasAutoStarted = true
            }
            // 확인 후 트래킹 중이면 화면 진입 시 즉시 재측정
            manager.refreshLuxReading()
        }
        .sheet(isPresented: $showManualEntry) {
            manualEntrySheet
        }
        .sheet(isPresented: $showBatteryTransfer) {
            batteryTransferSheet
        }
        // 처음 만나는 친구와 함께 받기 전 확인
        .alert(
            "\u{1F33B} \(manager.nearbyManager.pendingFriendRequest ?? "친구")이(가) 옆에서 햇빛을 받고 있어요!",
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
            if manager.lastKnownLux >= 10000 { return "강한 햇빛" }
            if manager.lastKnownLux >= 1000 { return "햇빛" }
            return "실외"
        }
        return manager.luxSensor.lightLevel.rawValue
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
                        .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: sensingPulse)
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
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 20).fill(Color(.secondarySystemGroupedBackground)))
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

            HStack {
                HStack(spacing: 6) {
                    Text(luxEmoji)
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

    // MARK: - 배터리 카드 (전달 버튼 내장)
    private var batteryCard: some View {
        VStack(spacing: 12) {
            HStack {
                Text("\u{26A1} 모은 햇빛")
                    .font(.subheadline.weight(.bold))
                Spacer()
                Text(formattedPercent(manager.batteryStatus.chargedAmount) + "%")
                    .font(.system(.title3, design: .rounded).weight(.bold))
                    .foregroundColor(.green)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.green.opacity(0.12))
                    Capsule()
                        .fill(LinearGradient(
                            colors: [Color(red: 0.5, green: 0.85, blue: 0.3), .green],
                            startPoint: .leading, endPoint: .trailing
                        ))
                        .frame(width: manager.batteryStatus.chargedAmount > 0 ?
                               max(12, geo.size.width * manager.batteryStatus.chargedAmount / 100) : 0)
                        .animation(.easeInOut(duration: 0.3), value: manager.batteryStatus.chargedAmount)
                }
            }
            .frame(height: 12)

            if manager.batteryStatus.chargedAmount > 0 {
                Button(action: {
                    transferAmount = manager.batteryStatus.chargedAmount
                    transferMax = max(manager.batteryStatus.chargedAmount, 0.1)
                    showBatteryTransfer = true
                }) {
                    Text("\u{1F33B} 해바라기에게 주기")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Capsule().fill(LinearGradient(
                            colors: [Color(red: 0.3, green: 0.7, blue: 0.2), .green],
                            startPoint: .leading, endPoint: .trailing
                        )))
                }
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 20).fill(Color(.secondarySystemGroupedBackground)))
    }

    // MARK: - Sun Progress (Sunflower)
    @State private var isSunflowerPressed = false
    @State private var showFloatingTip = false
    @State private var currentFloatingTip = ""
    @AppStorage("hasUsedDoubleTapToFinish") private var hasUsedDoubleTap = false

    private let floatingTips = [
        "햇빛 충전을 다 했으면 나를 더블탭해서 오늘의 일광욕을 마치자! 🌻",
        "실내로 돌아왔다면 해바라기를 더블탭해봐요 👆👆",
        "충분히 받았다면 나를 더블탭! 😊",
        "목표 달성했어? 그럼 나를 두 번 터치해서 끝내자! 🎯",
        "오늘의 일광욕을 마치려면 나를 더블탭! ☀️",
        "이제 그만 들어가도 괜찮아. 나를 두 번 눌러줘! 🏠"
    ]

    private var sunProgressSection: some View {
        VStack(spacing: 16) {
            // 해바라기 애니메이션
            ZStack {
                VStack(spacing: 8) {
                    SunAnimationView(
                        health: manager.sunflowerHealth.currentEnergy,
                        isTracking: manager.isSunlightDetected || manager.isConfirmedOutdoor,
                        petalColorState: manager.petalColorState,
                        friendName: manager.nearbyManager.isSharedActivityActive ?
                            manager.nearbyManager.connectedPeerNames.first : nil
                    )
                    .frame(height: 280)
                    .scaleEffect(isSunflowerPressed ? 1.15 : 1.2)
                    .frame(maxWidth: .infinity)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSunflowerPressed)

                    // 트래킹 중일 때 더블탭 힌트 (한 번도 사용 안 한 경우만)
                    if manager.isConfirmedOutdoor && !showFloatingTip && !hasUsedDoubleTap {
                        HStack(spacing: 6) {
                            Image(systemName: "hand.tap.fill")
                                .font(.caption)
                                .foregroundColor(.red)
                            Image(systemName: "hand.tap.fill")
                                .font(.caption)
                                .foregroundColor(.red)
                                .offset(x: -4)
                            Text("더블탭하여 종료")
                                .font(.caption.bold())
                                .foregroundColor(.red)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(Color.red.opacity(0.15))
                                .overlay(
                                    Capsule()
                                        .stroke(Color.red.opacity(0.3), lineWidth: 1)
                                )
                        )
                        .transition(.scale.combined(with: .opacity))
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture(count: 2) {
                    // 더블탭으로 트래킹 종료 또는 센서 재시작
                    if manager.isConfirmedOutdoor {
                        // 트래킹 중이면 종료
                        hasUsedDoubleTap = true  // 사용 기록 저장
                        withAnimation(.spring(duration: 0.3)) {
                            manager.finishTracking()
                        }
                    } else if !manager.isTracking {
                        // 센서가 꺼져있으면 다시 시작
                        withAnimation(.spring(duration: 0.3)) {
                            manager.startTracking()
                        }
                    }
                }
                .scaleEffect(isSunflowerPressed ? 0.95 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSunflowerPressed)

                // 플로팅 팁 (가끔 나타났다 사라짐)
                if showFloatingTip {
                    VStack {
                        Spacer()

                        Text(currentFloatingTip)
                            .font(.callout)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.black.opacity(0.75))
                                    .shadow(color: .black.opacity(0.3), radius: 8, y: 4)
                            )
                            .padding(.horizontal, 20)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                    .frame(maxHeight: 280)
                }
            }
            .onAppear {
                startFloatingTipTimer()
            }
            .onChange(of: manager.isConfirmedOutdoor) { _, isTracking in
                if isTracking {
                    startFloatingTipTimer()
                } else {
                    showFloatingTip = false
                }
            }

            // 해바라기 상태 (귀여운 캡슐)
            HStack(spacing: 6) {
                Text(healthEmoji)
                Text(manager.sunflowerHealth.healthState.rawValue)
                    .font(.subheadline.weight(.bold))
                    .foregroundColor(healthColor)
                Text("에너지 \(Int(manager.sunflowerHealth.currentEnergy))%")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Capsule().fill(healthColor.opacity(0.12)))
        }
        .padding(.vertical, 8)
    }

    private var healthEmoji: String {
        switch manager.sunflowerHealth.healthState {
        case .thriving: return "\u{2728}"
        case .healthy: return "\u{1F331}"
        case .wilting: return "\u{1F622}"
        case .critical: return "\u{1F940}"
        }
    }

    private var healthColor: Color {
        switch manager.sunflowerHealth.healthState {
        case .thriving: return .green
        case .healthy: return Color(red: 0.5, green: 0.7, blue: 0.3)
        case .wilting: return .orange
        case .critical: return .red
        }
    }

    /// 1% 미만은 소수점 한 자리로 표기 (0.4% 등)
    private func formattedPercent(_ value: Double) -> String {
        if value > 0 && value < 1 { return String(format: "%.1f", value) }
        return "\(Int(value))"
    }

    // MARK: - Battery Transfer Sheet
    private var batteryTransferSheet: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("해바라기에게 배터리를 전달합니다")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                VStack(spacing: 8) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("현재 배터리")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(Int(manager.batteryStatus.chargedAmount))%")
                                .font(.title3.bold())
                                .foregroundColor(.green)
                        }

                        Spacer()

                        Image(systemName: "arrow.right")
                            .foregroundColor(.secondary)

                        Spacer()

                        VStack(alignment: .trailing) {
                            Text("해바라기 에너지")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(Int(min(100, manager.sunflowerHealth.currentEnergy + transferAmount)))%")
                                .font(.title3.bold())
                                .foregroundColor(Color(red: 0.3, green: 0.7, blue: 0.2))
                        }
                    }
                    .padding()
                    .background(Color(.tertiarySystemGroupedBackground))
                    .cornerRadius(12)

                    Text("전달량: \(formattedPercent(transferAmount))%")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(.green)

                    Slider(value: $transferAmount, in: 0...transferMax)
                        .tint(.green)

                    HStack {
                        Text("0%").font(.caption2).foregroundColor(.secondary)
                        Spacer()
                        Button("전체") {
                            transferAmount = transferMax
                        }
                        .font(.caption.bold())
                        .foregroundColor(.green)
                        Spacer()
                        Text(formattedPercent(transferMax) + "%").font(.caption2).foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal)

                Button(action: {
                    manager.transferBattery(amount: transferAmount)
                    showBatteryTransfer = false
                }) {
                    Text("전달하기")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.green)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
                .disabled(transferAmount <= 0)

                Spacer()
            }
            .padding(.top, 20)
            .navigationTitle("배터리 전달")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { showBatteryTransfer = false }
                }
            }
        }
        .presentationDetents([.medium, .large])
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
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(.orange)

                    Slider(value: $manualMinutes, in: 5...120, step: 5)
                        .tint(.orange)

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
                    Button("취소") { showManualEntry = false }
                }
            }
        }
        .presentationDetents([.medium])
    }

    // MARK: - Helpers
    private func startFloatingTipTimer() {
        // 트래킹 중이 아니거나 이미 더블탭 사용한 적 있으면 타이머 시작 안함
        guard manager.isConfirmedOutdoor, !hasUsedDoubleTap else { return }

        // 30~60초 후 첫 팁 표시
        let initialDelay = Double.random(in: 30...60)

        DispatchQueue.main.asyncAfter(deadline: .now() + initialDelay) {
            self.showRandomFloatingTip()
        }
    }

    private func showRandomFloatingTip() {
        // 트래킹 중이 아니거나 이미 더블탭 사용한 적 있으면 표시 안함
        guard manager.isConfirmedOutdoor, !hasUsedDoubleTap else { return }

        // 랜덤 팁 선택
        currentFloatingTip = floatingTips.randomElement() ?? floatingTips[0]

        // 팁 표시
        withAnimation(.spring(duration: 0.5)) {
            showFloatingTip = true
        }

        // 4초 후 숨김
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            withAnimation(.spring(duration: 0.5)) {
                self.showFloatingTip = false
            }

            // 다음 팁을 위해 40~80초 후 다시 표시
            let nextDelay = Double.random(in: 40...80)
            DispatchQueue.main.asyncAfter(deadline: .now() + nextDelay) {
                self.showRandomFloatingTip()
            }
        }
    }
}

// MARK: - Pulse Modifier
struct PulseModifier: ViewModifier {
    @State private var isPulsing = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(isPulsing ? 1.3 : 1.0)
            .opacity(isPulsing ? 0.5 : 1.0)
            .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: isPulsing)
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
            return "\(friendName)이(가) 옆에서 같이 받는 중!"
        }
        return "\(peerCount)명이랑 같이 받는 중!"
    }

    var body: some View {
        HStack(spacing: 10) {
            Text("\u{1F33B}\u{1F49B}\u{1F33B}")
                .font(.subheadline)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.bold))
                    .foregroundColor(Color(red: 0.85, green: 0.5, blue: 0.1))
                    .lineLimit(1)
                if let dist = distance {
                    Text(String(format: "바로 옆 %.1fm \u{1F31E}", dist))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            Circle()
                .fill(Color.orange)
                .frame(width: 9, height: 9)
                .modifier(PulseModifier())
        }
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

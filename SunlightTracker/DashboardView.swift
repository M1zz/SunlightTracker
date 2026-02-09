import SwiftUI

struct DashboardView: View {
    @ObservedObject var manager: SunlightManager
    @ObservedObject var weatherService: WeatherService
    @State private var showManualEntry = false
    @State private var manualMinutes: Double = 15
    @State private var hasAutoStarted = false
    @State private var showBatteryTransfer = false
    @State private var transferAmount: Double = 0
    @State private var currentTip: HealthTip = HealthTip.allTips.randomElement()!

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
        ScrollView {
            VStack(spacing: 20) {
                // 해바라기 상태
                sunProgressSection

                // 조도 게이지 (감지 중 또는 확인 후 트래킹 중)
                if manager.trackingPhase == .detecting || manager.trackingPhase == .confirmed {
                    luxGaugeSection
                }

                // 배터리 상태
                batterySection

                // 확인 후 트래킹 중 - 경과 시간 & 종료 버튼
                if manager.trackingPhase == .confirmed {
                    confirmedTrackingSection
                }

                // 배터리 전달 버튼
                if manager.batteryStatus.chargedAmount > 0 {
                    batteryTransferButton
                }

                // 건강 조언 카드
                healthAdviceCard

                // 감지 단계 또는 대기 상태 버튼
                if manager.trackingPhase != .confirmed {
                    trackingButton
                }

                // 수동 입력
                manualEntryButton

                todayStatsSection

                if let sunTimes = manager.sunTimes {
                    sunTimesSection(sunTimes)
                }

                // 오늘 세션 목록
                if !manager.todayRecord.sessions.isEmpty {
                    todaySessionsSection
                }

                weeklyPreviewSection
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 30)
        }
        .background(Color(.systemGroupedBackground))
        .onAppear {
            weatherService.fetchSimulatedWeather()
            manager.requestLocation()
            // 앱 시작 시 자동으로 조도 센서 시작
            if !hasAutoStarted && manager.trackingPhase == .idle {
                manager.startTracking()
                hasAutoStarted = true
            }
        }
        .sheet(isPresented: $showManualEntry) {
            manualEntrySheet
        }
        .sheet(isPresented: $showBatteryTransfer) {
            batteryTransferSheet
        }
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

    private var luxGaugeSection: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: manager.isConfirmedOutdoor ? "checkmark.circle.fill" : "sun.max.fill")
                    .foregroundColor(batteryColor)
                Text(displayLightLevel)
                    .font(.headline)
                    .foregroundColor(batteryColor)
                Spacer()
                Text("\(displayLux.luxFormatted) Lux")
                    .font(.title3.bold())
                    .foregroundColor(batteryColor)
            }

            // 조도 바 게이지
            VStack(spacing: 8) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        // 배경 바 (3단계 그라데이션)
                        LinearGradient(
                            colors: [
                                Color.green.opacity(0.3),
                                Color.orange.opacity(0.3),
                                Color.red.opacity(0.3)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(height: 32)
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )

                        // 구간 구분선
                        HStack(spacing: 0) {
                            Spacer()
                                .frame(width: geo.size.width * 0.33)
                            Rectangle()
                                .fill(Color.white.opacity(0.5))
                                .frame(width: 2, height: 32)
                            Spacer()
                                .frame(width: geo.size.width * 0.34)
                            Rectangle()
                                .fill(Color.white.opacity(0.5))
                                .frame(width: 2, height: 32)
                            Spacer()
                        }

                        // 현재 조도 인디케이터 (다이아몬드)
                        let position = luxToPosition(displayLux, totalWidth: geo.size.width)
                        ZStack {
                            // 그림자
                            Diamond()
                                .fill(Color.black.opacity(0.2))
                                .frame(width: 20, height: 20)
                                .offset(x: position, y: 2)

                            // 메인 다이아몬드
                            Diamond()
                                .fill(batteryColor)
                                .frame(width: 18, height: 18)
                                .overlay(
                                    Diamond()
                                        .stroke(Color.white, lineWidth: 2)
                                        .frame(width: 18, height: 18)
                                )
                                .offset(x: position)
                                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: displayLux)
                        }
                    }
                }
                .frame(height: 32)

                // 레이블
                HStack(spacing: 0) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("실내")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.green)
                        Text("0-300")
                            .font(.system(size: 8))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    VStack(spacing: 2) {
                        Text("실외")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.orange)
                        Text("300-1k")
                            .font(.system(size: 8))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)

                    VStack(alignment: .trailing, spacing: 2) {
                        Text("햇빛")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.red)
                        Text("1k+")
                            .font(.system(size: 8))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }

    // 조도 값을 바 위치로 변환
    private func luxToPosition(_ lux: Double, totalWidth: Double) -> Double {
        let maxLux = 10000.0
        let ratio = min(lux / maxLux, 1.0)
        return (totalWidth - 18) * ratio // 18은 다이아몬드 크기
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
                        isTracking: manager.isSunlightDetected || manager.isConfirmedOutdoor
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

            // 해바라기 상태 표시
            HStack(spacing: 8) {
                Image(systemName: healthIcon)
                    .foregroundColor(healthColor)
                Text(manager.sunflowerHealth.healthState.rawValue)
                    .font(.headline)
                Spacer()
                Text("에너지: \(Int(manager.sunflowerHealth.currentEnergy))%")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(12)
            .frame(maxWidth: .infinity)
            .background(RoundedRectangle(cornerRadius: 12).fill(healthColor.opacity(0.1)))
            .padding(.horizontal, 16)
        }
        .padding(.vertical, 8)
    }

    private var healthIcon: String {
        switch manager.sunflowerHealth.healthState {
        case .thriving: return "sparkles"
        case .healthy: return "leaf.fill"
        case .wilting: return "exclamationmark.triangle.fill"
        case .critical: return "exclamationmark.octagon.fill"
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

    // MARK: - Battery Section
    private var batterySection: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "bolt.fill")
                    .foregroundColor(.green)
                Text("충전된 배터리")
                    .font(.headline)
                Spacer()
                Text("\(Int(manager.batteryStatus.chargedAmount))%")
                    .font(.title2.bold())
                    .foregroundColor(.green)
            }

            // 5등분 배터리 세그먼트
            HStack(spacing: 6) {
                ForEach(0..<5, id: \.self) { index in
                    let segmentThreshold = Double((index + 1) * 20)
                    let isFilled = manager.batteryStatus.chargedAmount >= segmentThreshold - 10

                    if index == 4 {
                        // 마지막 칸 - 배터리 팁 모양
                        HStack(spacing: 0) {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(isFilled ?
                                    LinearGradient(
                                        colors: [.green, Color(red: 0.5, green: 0.85, blue: 0.3)],
                                        startPoint: .bottom, endPoint: .top
                                    ) :
                                    LinearGradient(
                                        colors: [Color.gray.opacity(0.2), Color.gray.opacity(0.2)],
                                        startPoint: .bottom, endPoint: .top
                                    )
                                )
                                .frame(height: 40)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(Color.green.opacity(0.3), lineWidth: 1)
                                )

                            // 배터리 팁
                            RoundedRectangle(cornerRadius: 3)
                                .fill(isFilled ? Color.green : Color.gray.opacity(0.3))
                                .frame(width: 4, height: 20)
                                .padding(.leading, 2)
                        }
                        .animation(.easeInOut(duration: 0.3), value: manager.batteryStatus.chargedAmount)
                    } else {
                        // 일반 칸
                        RoundedRectangle(cornerRadius: 6)
                            .fill(isFilled ?
                                LinearGradient(
                                    colors: [.green, Color(red: 0.5, green: 0.85, blue: 0.3)],
                                    startPoint: .bottom, endPoint: .top
                                ) :
                                LinearGradient(
                                    colors: [Color.gray.opacity(0.2), Color.gray.opacity(0.2)],
                                    startPoint: .bottom, endPoint: .top
                                )
                            )
                            .frame(height: 40)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color.green.opacity(0.3), lineWidth: 1)
                            )
                            .animation(.easeInOut(duration: 0.3), value: manager.batteryStatus.chargedAmount)
                    }
                }
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(.secondarySystemGroupedBackground)))
    }

    // MARK: - Battery Transfer Button
    private var batteryTransferButton: some View {
        Button(action: {
            transferAmount = manager.batteryStatus.chargedAmount
            showBatteryTransfer = true
        }) {
            HStack(spacing: 12) {
                Image(systemName: "arrow.right.circle.fill")
                    .font(.title2)

                VStack(alignment: .leading, spacing: 2) {
                    Text("배터리 전달하기")
                        .font(.headline)
                    Text("해바라기에게 에너지를 전달하세요")
                        .font(.caption)
                        .opacity(0.8)
                }

                Spacer()

                Text("\(Int(manager.batteryStatus.chargedAmount))%")
                    .font(.title3.bold())
                    .foregroundColor(.white.opacity(0.9))
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .foregroundColor(.white)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(LinearGradient(
                        colors: [Color(red: 0.3, green: 0.7, blue: 0.2), .green],
                        startPoint: .leading, endPoint: .trailing
                    ))
            )
            .shadow(color: Color.green.opacity(0.3), radius: 8, y: 4)
        }
        .disabled(manager.batteryStatus.chargedAmount <= 0)
        .opacity(manager.batteryStatus.chargedAmount > 0 ? 1.0 : 0.5)
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

                    Text("전달량: \(Int(transferAmount))%")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(.green)

                    Slider(value: $transferAmount, in: 0...manager.batteryStatus.chargedAmount, step: 1)
                        .tint(.green)

                    HStack {
                        Text("0%").font(.caption2).foregroundColor(.secondary)
                        Spacer()
                        Button("전체") {
                            transferAmount = manager.batteryStatus.chargedAmount
                        }
                        .font(.caption.bold())
                        .foregroundColor(.green)
                        Spacer()
                        Text("\(Int(manager.batteryStatus.chargedAmount))%").font(.caption2).foregroundColor(.secondary)
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

    // MARK: - Health Advice Card
    private var healthAdviceCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 랜덤 건강 팁
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: "lightbulb.fill")
                        .foregroundColor(.orange)
                        .font(.caption)
                    Text("오늘의 건강 팁")
                        .font(.caption.bold())
                        .foregroundColor(.orange)

                    Spacer()

                    Button(action: {
                        currentTip = manager.getRandomHealthTip()
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }

                HStack(spacing: 12) {
                    Image(systemName: currentTip.icon)
                        .font(.title2)
                        .foregroundColor(Color(hex: currentTip.color) ?? .blue)
                        .frame(width: 44, height: 44)
                        .background(Circle().fill((Color(hex: currentTip.color) ?? .blue).opacity(0.15)))

                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Text(currentTip.category.rawValue)
                                .font(.system(size: 10))
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(Color(hex: currentTip.color) ?? .blue))

                            Text(currentTip.title)
                                .font(.subheadline.bold())
                                .foregroundColor(.primary)
                        }
                    }
                }

                Text(currentTip.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(4)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let achieved = manager.currentAdvice(for: displayMinutes) {
                Divider()

                // 달성한 효과
                HStack(spacing: 10) {
                    Image(systemName: achieved.icon)
                        .font(.title3)
                        .foregroundColor(.white)
                        .frame(width: 36, height: 36)
                        .background(Circle().fill(Color.green))

                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(displayMinutes)분 달성!")
                            .font(.caption.bold())
                            .foregroundColor(.green)
                        Text(achieved.title)
                            .font(.caption)
                    }
                }

                Text(achieved.description)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            if let next = manager.nextMilestoneAdvice(for: displayMinutes) {
                HStack(spacing: 10) {
                    Image(systemName: next.advice.icon)
                        .font(.caption)
                        .foregroundColor(.orange)
                        .frame(width: 24, height: 24)
                        .background(Circle().fill(Color.orange.opacity(0.15)))

                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(next.remainingMinutes)분 후")
                            .font(.caption2.bold())
                            .foregroundColor(.orange)
                        Text(next.advice.title)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }

                    Spacer()
                }
            }

            // 동기부여 메시지
            Text(manager.motivationalMessage)
                .font(.caption)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(
                    LinearGradient(
                        colors: [Color(red: 0.3, green: 0.7, blue: 0.2), Color(red: 0.9, green: 0.8, blue: 0.1)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .cornerRadius(10)
                )
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }

    // MARK: - Confirmed Tracking Section (센서 꺼짐, 타이머 진행 중)
    private var confirmedTrackingSection: some View {
        VStack(spacing: 12) {
            // 트래킹 상태
            HStack(spacing: 8) {
                Circle()
                    .fill(Color.green)
                    .frame(width: 10, height: 10)
                    .modifier(PulseModifier())
                Text("햇빛 트래킹 중")
                    .font(.headline)
                    .foregroundColor(Color(red: 0.3, green: 0.65, blue: 0.2))
                Spacer()
                Text("\(manager.confirmedElapsedMinutes)분 경과")
                    .font(.subheadline.bold())
                    .foregroundColor(.primary)
            }

            // 실시간 충전 예상량
            HStack {
                Image(systemName: "bolt.fill")
                    .foregroundColor(.yellow)
                Text("예상 충전량:")
                    .font(.subheadline)
                Spacer()
                Text("+\(Int(manager.estimatedBatteryGain))%")
                    .font(.headline.bold())
                    .foregroundColor(.green)
            }
            .padding(12)
            .background(Color.green.opacity(0.1))
            .cornerRadius(10)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.green.opacity(0.4), lineWidth: 2)
                )
        )
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
            HStack(spacing: 12) {
                Image(systemName: manager.trackingPhase == .detecting ? "stop.circle.fill" : "camera.metering.spot")
                    .font(.title2)

                VStack(alignment: .leading, spacing: 2) {
                    Text(manager.trackingPhase == .detecting ? "감지 중지" : "조도 센서 시작")
                        .font(.headline)
                    Text(manager.trackingPhase == .detecting ?
                         "해바라기가 햇빛을 기다리고 있어요..." :
                         "카메라로 주변 밝기를 측정합니다")
                        .font(.caption)
                        .opacity(0.8)
                }

                Spacer()

                if manager.trackingPhase == .detecting {
                    Circle()
                        .fill(Color.white.opacity(0.5))
                        .frame(width: 10, height: 10)
                        .modifier(PulseModifier())
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .foregroundColor(.white)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(manager.trackingPhase == .detecting ?
                          LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing) :
                          LinearGradient(colors: [.orange, Color(red: 1.0, green: 0.85, blue: 0.1)], startPoint: .leading, endPoint: .trailing)
                    )
            )
            .shadow(color: (manager.trackingPhase == .detecting ? Color.blue : Color.orange).opacity(0.3), radius: 8, y: 4)
        }
    }

    // MARK: - Manual Entry
    private var manualEntryButton: some View {
        Button(action: { showManualEntry = true }) {
            HStack {
                Image(systemName: "plus.circle")
                Text("수동으로 시간 추가")
                    .font(.subheadline)
            }
            .foregroundColor(.orange)
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

    // MARK: - Today Stats
    private var todayStatsSection: some View {
        VStack(spacing: 12) {
            // 햇빛 시간 반원 레이더 게이지
            VStack(spacing: 16) {
                HStack {
                    Image(systemName: "sun.max.fill")
                        .foregroundColor(.orange)
                    Text("오늘의 햇빛")
                        .font(.headline)
                    Spacer()
                    Text("\(displayMinutes) / \(manager.settings.dailyGoalMinutes)분")
                        .font(.subheadline.bold())
                        .foregroundColor(displayProgress >= 1.0 ? .green : .orange)
                }

                // 반원 레이더 게이지
                ZStack {
                    // 배경 반원 (회색)
                    SemicircleShape()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 20)
                        .frame(height: 120)

                    // 진행도 반원
                    SemicircleShape()
                        .trim(from: 0, to: min(displayProgress, 1.0))
                        .stroke(
                            LinearGradient(
                                colors: displayProgress >= 1.0 ?
                                    [.green, Color(red: 0.3, green: 0.7, blue: 0.2)] :
                                    [.orange, .yellow],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            style: StrokeStyle(lineWidth: 20, lineCap: .round)
                        )
                        .frame(height: 120)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 0.8), value: displayProgress)

                    // 중앙 텍스트
                    VStack(spacing: 4) {
                        Text("\(Int(displayProgress * 100))%")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(displayProgress >= 1.0 ? .green : .orange)

                        if displayProgress >= 1.0 {
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.caption)
                                Text("달성!")
                                    .font(.caption.bold())
                            }
                            .foregroundColor(.green)
                        }
                    }
                    .offset(y: 20)
                }
                .padding(.vertical, 10)
            }
            .padding(16)
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(16)

            // 추가 통계
            HStack(spacing: 12) {
                StatCard(icon: "light.max", title: "최고 조도",
                         value: manager.todayRecord.peakLux.luxFormatted + " lx", color: .yellow)
                StatCard(icon: "number", title: "세션", value: "\(manager.todayRecord.sessions.count)회", color: .purple)
            }
        }
    }

    // MARK: - Sun Times
    private func sunTimesSection(_ sunTimes: SunTimes) -> some View {
        HStack(spacing: 0) {
            VStack(spacing: 6) {
                Image(systemName: "sunrise.fill").font(.title2).foregroundColor(.orange)
                Text("일출").font(.caption).foregroundColor(.secondary)
                Text(sunTimes.sunrise.timeString).font(.subheadline.bold())
            }
            .frame(maxWidth: .infinity)

            Rectangle().fill(Color.gray.opacity(0.2)).frame(width: 1, height: 50)

            VStack(spacing: 6) {
                Image(systemName: "sun.max.fill").font(.title2).foregroundColor(.yellow)
                Text("일조시간").font(.caption).foregroundColor(.secondary)
                Text(sunTimes.daylightDescription).font(.subheadline.bold())
            }
            .frame(maxWidth: .infinity)

            Rectangle().fill(Color.gray.opacity(0.2)).frame(width: 1, height: 50)

            VStack(spacing: 6) {
                Image(systemName: "sunset.fill").font(.title2).foregroundColor(.red)
                Text("일몰").font(.caption).foregroundColor(.secondary)
                Text(sunTimes.sunset.timeString).font(.subheadline.bold())
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.vertical, 16)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }

    // MARK: - Today Sessions
    private var todaySessionsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("오늘의 세션")
                .font(.headline)

            ForEach(manager.todayRecord.sessions) { session in
                HStack(spacing: 12) {
                    Image(systemName: session.autoDetected ? "camera.metering.spot" : "hand.tap")
                        .font(.caption)
                        .foregroundColor(session.autoDetected ? .orange : .blue)
                        .frame(width: 24)

                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            Text(session.startTime.shortTimeString)
                            if let end = session.endTime {
                                Text("→ \(end.shortTimeString)")
                            }
                            Text("(\(session.durationMinutes)분)")
                                .foregroundColor(.secondary)
                        }
                        .font(.subheadline)

                        HStack(spacing: 8) {
                            Text(session.luxDescription)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("평균 \(Int(session.averageLux)) lx")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("최고 \(Int(session.peakLux)) lx")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    }

                    Spacer()
                }
                .padding(10)
                .background(Color(.tertiarySystemGroupedBackground))
                .cornerRadius(10)
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }

    // MARK: - Weekly Preview (Sunflower themed)
    private var weeklyPreviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("이번 주")
                .font(.headline)

            HStack(spacing: 8) {
                ForEach(manager.getLast7DaysData(), id: \.0) { day, minutes, avgLux in
                    VStack(spacing: 6) {
                        // 해바라기 아이콘 (목표 달성 시)
                        if minutes >= manager.settings.dailyGoalMinutes {
                            Image(systemName: "leaf.circle.fill")
                                .font(.system(size: 18))
                                .foregroundColor(Color(red: 0.3, green: 0.7, blue: 0.2))
                        } else {
                            Image(systemName: "leaf.circle")
                                .font(.system(size: 18))
                                .foregroundColor(.gray.opacity(0.4))
                        }

                        ZStack(alignment: .bottom) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.gray.opacity(0.1))
                                .frame(width: 32, height: 60)

                            RoundedRectangle(cornerRadius: 4)
                                .fill(
                                    minutes >= manager.settings.dailyGoalMinutes ?
                                    LinearGradient(colors: [Color(red: 0.3, green: 0.7, blue: 0.2), Color(red: 1.0, green: 0.85, blue: 0.1)], startPoint: .bottom, endPoint: .top) :
                                    LinearGradient(colors: [Color(red: 0.3, green: 0.7, blue: 0.2).opacity(0.4), Color(red: 1.0, green: 0.85, blue: 0.1).opacity(0.4)], startPoint: .bottom, endPoint: .top)
                                )
                                .frame(
                                    width: 32,
                                    height: max(4, CGFloat(min(minutes, manager.settings.dailyGoalMinutes)) / CGFloat(max(manager.settings.dailyGoalMinutes, 1)) * 60)
                                )
                        }

                        Text(day)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }

            HStack {
                Circle()
                    .fill(Color(red: 0.3, green: 0.7, blue: 0.2))
                    .frame(width: 8, height: 8)
                Text("목표: \(manager.settings.dailyGoalMinutes)분")
                    .font(.caption2).foregroundColor(.secondary)
                Spacer()
                let summary = manager.getWeeklySummary()
                Text("주간 평균 \(Int(summary.averageMinutes))분")
                    .font(.caption2).foregroundColor(.secondary)
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }

    // MARK: - Helpers
    private func luxColor(_ lux: Double) -> Color {
        switch lux {
        case ..<50: return .gray
        case 50..<300: return .yellow
        case 300..<1000: return .cyan
        case 1000..<10000: return .orange
        default: return .red
        }
    }

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

// MARK: - Lux Battery View
struct LuxBatteryView: View {
    let lux: Double
    let threshold: Double

    private var fillRatio: Double {
        guard lux > 0 else { return 0 }
        return min(log10(lux) / 5.0, 1.0) // log10(100000) = 5
    }

    private var thresholdRatio: Double {
        guard threshold > 0 else { return 0 }
        return min(log10(threshold) / 5.0, 1.0)
    }

    private var fillColor: LinearGradient {
        if lux >= threshold {
            return LinearGradient(colors: [Color(red: 0.3, green: 0.7, blue: 0.2), Color(red: 0.5, green: 0.85, blue: 0.3)], startPoint: .leading, endPoint: .trailing)
        }
        return LinearGradient(colors: [.orange.opacity(0.6), .orange], startPoint: .leading, endPoint: .trailing)
    }

    var body: some View {
        GeometryReader { geo in
            HStack(spacing: 2) {
                // 배터리 본체
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1.5)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.08))

                    // 채워진 부분
                    RoundedRectangle(cornerRadius: 4)
                        .fill(fillColor)
                        .padding(2)
                        .frame(width: max(0, (geo.size.width - 8) * fillRatio))
                        .animation(.easeInOut(duration: 1.5), value: fillRatio)

                    // 기준선
                    Rectangle()
                        .fill(Color.orange.opacity(0.8))
                        .frame(width: 1.5, height: geo.size.height - 4)
                        .offset(x: (geo.size.width - 8) * thresholdRatio)
                }

                // 배터리 단자
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 4, height: geo.size.height * 0.45)
            }
        }
    }
}

// MARK: - StatCard
struct StatCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon).font(.title3).foregroundColor(color)
            Text(title).font(.caption).foregroundColor(.secondary)
            Text(value).font(.headline)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
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

// MARK: - Semicircle Shape
struct SemicircleShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.maxY)
        let radius = rect.width / 2

        path.addArc(
            center: center,
            radius: radius,
            startAngle: .degrees(180),
            endAngle: .degrees(0),
            clockwise: false
        )

        return path
    }
}

// MARK: - Wiper Shape (와이퍼/바늘)
struct WiperShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        // 바늘 모양 (삼각형 + 직사각형)
        let width = rect.width
        let height = rect.height

        // 뾰족한 끝
        path.move(to: CGPoint(x: width / 2, y: 0))
        path.addLine(to: CGPoint(x: width, y: height * 0.2))
        path.addLine(to: CGPoint(x: width, y: height))
        path.addLine(to: CGPoint(x: 0, y: height))
        path.addLine(to: CGPoint(x: 0, y: height * 0.2))
        path.closeSubpath()

        return path
    }
}

// MARK: - Diamond Shape (다이아몬드 인디케이터)
struct Diamond: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height

        path.move(to: CGPoint(x: width / 2, y: 0))
        path.addLine(to: CGPoint(x: width, y: height / 2))
        path.addLine(to: CGPoint(x: width / 2, y: height))
        path.addLine(to: CGPoint(x: 0, y: height / 2))
        path.closeSubpath()

        return path
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

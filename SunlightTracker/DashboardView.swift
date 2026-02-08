import SwiftUI

struct DashboardView: View {
    @ObservedObject var manager: SunlightManager
    @ObservedObject var weatherService: WeatherService
    @State private var showManualEntry = false
    @State private var manualMinutes: Double = 15
    @State private var hasAutoStarted = false

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
                headerSection

                // 조도 게이지 (감지 중 또는 확인 후 트래킹 중)
                if manager.trackingPhase == .detecting || manager.trackingPhase == .confirmed {
                    luxGaugeSection
                }

                sunProgressSection

                // 확인 후 트래킹 중 - 경과 시간 & 종료 버튼
                if manager.trackingPhase == .confirmed {
                    confirmedTrackingSection
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
    }

    // MARK: - Header
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("나의 해바라기")
                    .font(.title2.bold())
                Text(Date().shortDateString)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()
            if manager.streakCount > 0 {
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .foregroundColor(.orange)
                    Text("\(manager.streakCount)일 연속")
                        .font(.subheadline.bold())
                        .foregroundColor(.orange)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.orange.opacity(0.12))
                .cornerRadius(20)
            }
        }
        .padding(.top, 10)
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
        VStack(spacing: 10) {
            HStack {
                Image(systemName: manager.isConfirmedOutdoor ? "checkmark.circle.fill" : "sun.max.fill")
                    .foregroundColor(batteryColor)
                    .font(.subheadline)
                Text(displayLightLevel)
                    .font(.subheadline.bold())
                    .foregroundColor(batteryColor)
                Spacer()
                Text("\(Int(displayLux)) Lux")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // 배터리 게이지
            LuxBatteryView(
                lux: displayLux,
                threshold: manager.settings.outdoorThresholdLux
            )
            .frame(height: 28)

            HStack {
                Text("실내")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                Spacer()
                Text("기준")
                    .font(.system(size: 10))
                    .foregroundColor(.orange)
                Spacer()
                Text("햇빛")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }

    // MARK: - Sun Progress (Sunflower)
    private var sunProgressSection: some View {
        VStack(spacing: 16) {
            SunAnimationView(
                progress: displayProgress,
                isTracking: manager.isSunlightDetected || manager.isConfirmedOutdoor
            )

            HStack(spacing: 4) {
                Text("\(displayMinutes)")
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                Text("/ \(manager.todayRecord.goalMinutes)분")
                    .font(.title3)
                    .foregroundColor(.secondary)
            }

            if manager.todayRecord.goalAchieved {
                Label("만개 달성!", systemImage: "checkmark.circle.fill")
                    .font(.headline)
                    .foregroundColor(.green)
            }
        }
        .padding(.vertical, 10)
    }

    // MARK: - Health Advice Card
    private var healthAdviceCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let achieved = manager.currentAdvice(for: displayMinutes) {
                // 달성한 효과
                HStack(spacing: 10) {
                    Image(systemName: achieved.icon)
                        .font(.title2)
                        .foregroundColor(.white)
                        .frame(width: 40, height: 40)
                        .background(Circle().fill(Color.green))

                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(displayMinutes)분 달성!")
                            .font(.caption.bold())
                            .foregroundColor(.green)
                        Text(achieved.title)
                            .font(.subheadline.bold())
                    }
                }

                Text(achieved.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
            }

            if let next = manager.nextMilestoneAdvice(for: displayMinutes) {
                Divider()

                HStack(spacing: 10) {
                    Image(systemName: next.advice.icon)
                        .font(.title3)
                        .foregroundColor(.orange)
                        .frame(width: 32, height: 32)
                        .background(Circle().fill(Color.orange.opacity(0.15)))

                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 4) {
                            Text("\(next.remainingMinutes)분 후")
                                .font(.caption.bold())
                                .foregroundColor(.orange)
                            Text(next.advice.category.rawValue)
                                .font(.system(size: 10))
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 1)
                                .background(Capsule().fill(Color.orange.opacity(0.7)))
                        }
                        Text(next.advice.title)
                            .font(.caption)
                            .foregroundColor(.primary)
                    }

                    Spacer()
                }
            }

            // 동기부여 메시지
            Text(manager.motivationalMessage)
                .font(.footnote)
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
        VStack(spacing: 16) {
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

            Text("조도 센서가 꺼져 배터리를 절약하고 있어요. 실내로 돌아오면 아래 버튼을 눌러주세요.")
                .font(.caption)
                .foregroundColor(.secondary)

            Button(action: {
                manager.finishTracking()
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "stop.circle.fill")
                        .font(.title3)
                    Text("트래킹 종료")
                        .font(.headline)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(
                        colors: [Color(red: 0.3, green: 0.65, blue: 0.2), .orange],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .cornerRadius(12)
                )
            }
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
        HStack(spacing: 12) {
            StatCard(icon: "clock.fill", title: "총 시간", value: "\(displayMinutes)분", color: .blue)
            StatCard(icon: "sun.max.trianglebadge.exclamationmark", title: "최고 조도",
                     value: manager.todayRecord.peakLux.luxFormatted + " lx", color: .orange)
            StatCard(icon: "number", title: "세션", value: "\(manager.todayRecord.sessions.count)회", color: .purple)
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

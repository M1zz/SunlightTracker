import SwiftUI

struct DashboardView: View {
    @ObservedObject var manager: SunlightManager
    @ObservedObject var weatherService: WeatherService
    @State private var showManualEntry = false
    @State private var manualMinutes: Double = 15
    
    private var currentSessionMinutes: Int {
        guard let session = manager.currentSession else { return 0 }
        return max(Int(Date().timeIntervalSince(session.startTime) / 60), 0)
    }
    
    private var displayMinutes: Int {
        manager.todayRecord.totalMinutes + (manager.isSunlightDetected ? currentSessionMinutes : 0)
    }
    
    private var displayProgress: Double {
        guard manager.todayRecord.goalMinutes > 0 else { return 0 }
        return min(Double(displayMinutes) / Double(manager.todayRecord.goalMinutes), 1.0)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                headerSection
                
                // 실시간 조도 모니터
                if manager.isTracking {
                    luxMonitorSection
                }
                
                sunProgressSection
                trackingButton
                
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
        }
        .sheet(isPresented: $showManualEntry) {
            manualEntrySheet
        }
    }
    
    // MARK: - Header
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("오늘의 일조량")
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
                    Text("\(manager.streakCount)일")
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
    
    // MARK: - 실시간 조도 모니터
    private var luxMonitorSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("실시간 조도")
                    .font(.headline)
                Spacer()
                
                // 상태 인디케이터
                HStack(spacing: 6) {
                    Circle()
                        .fill(manager.isSunlightDetected ? Color.green : Color.gray)
                        .frame(width: 8, height: 8)
                        .modifier(PulseModifier())
                    Text(manager.isSunlightDetected ? "햇빛 감지 중" : "대기 중")
                        .font(.caption)
                        .foregroundColor(manager.isSunlightDetected ? .green : .secondary)
                }
            }
            
            HStack(alignment: .bottom, spacing: 16) {
                // 현재 Lux
                VStack(alignment: .leading, spacing: 4) {
                    Text(manager.luxSensor.lightLevel.emoji)
                        .font(.system(size: 36))
                    Text("\(Int(manager.luxSensor.currentLux))")
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundColor(luxColor(manager.luxSensor.currentLux))
                    Text("Lux")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // 조도 바
                VStack(alignment: .trailing, spacing: 8) {
                    Text(manager.luxSensor.lightLevel.rawValue)
                        .font(.subheadline.bold())
                        .foregroundColor(luxColor(manager.luxSensor.currentLux))
                    
                    LuxBarView(
                        currentLux: manager.luxSensor.currentLux,
                        threshold: manager.settings.outdoorThresholdLux
                    )
                    .frame(height: 40)
                    
                    HStack {
                        Text("실내")
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("기준 \(Int(manager.settings.outdoorThresholdLux))")
                            .font(.system(size: 9))
                            .foregroundColor(.orange)
                        Spacer()
                        Text("강한 햇빛")
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            
            // 세션 진행 중 표시
            if manager.isSunlightDetected, let session = manager.currentSession {
                HStack {
                    Image(systemName: "record.circle")
                        .foregroundColor(.red)
                        .font(.caption)
                    Text("세션 진행: \(currentSessionMinutes)분 경과")
                        .font(.caption.bold())
                    Spacer()
                    Text("평균 \(Int(session.luxSamples.isEmpty ? 0 : session.luxSamples.reduce(0,+) / Double(session.luxSamples.count))) Lux")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 4)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            manager.isSunlightDetected ? Color.orange.opacity(0.5) : Color.clear,
                            lineWidth: 2
                        )
                )
        )
    }
    
    // MARK: - Sun Progress
    private var sunProgressSection: some View {
        VStack(spacing: 16) {
            SunAnimationView(
                progress: displayProgress,
                isTracking: manager.isSunlightDetected
            )
            .frame(height: 240)
            
            HStack(spacing: 4) {
                Text("\(displayMinutes)")
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                Text("/ \(manager.todayRecord.goalMinutes)분")
                    .font(.title3)
                    .foregroundColor(.secondary)
            }
            
            if manager.todayRecord.goalAchieved {
                Label("목표 달성! 🎉", systemImage: "checkmark.circle.fill")
                    .font(.headline)
                    .foregroundColor(.green)
            }
        }
        .padding(.vertical, 10)
    }
    
    // MARK: - Tracking Button
    private var trackingButton: some View {
        Button(action: {
            if manager.isTracking {
                manager.stopTracking()
            } else {
                manager.startTracking()
            }
        }) {
            HStack(spacing: 12) {
                Image(systemName: manager.isTracking ? "stop.circle.fill" : "camera.metering.spot")
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(manager.isTracking ? "조도 센서 중지" : "조도 센서 시작")
                        .font(.headline)
                    Text(manager.isTracking ?
                         (manager.isSunlightDetected ? "☀️ 햇빛 감지 중 - 자동 기록" : "📡 조도 모니터링 중...") :
                         "카메라로 주변 밝기를 측정합니다")
                        .font(.caption)
                        .opacity(0.8)
                }
                
                Spacer()
                
                if manager.isTracking {
                    Circle()
                        .fill(manager.isSunlightDetected ? Color.green : Color.white.opacity(0.5))
                        .frame(width: 10, height: 10)
                        .modifier(PulseModifier())
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .foregroundColor(.white)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(manager.isTracking ?
                          (manager.isSunlightDetected ?
                           LinearGradient(colors: [.orange, .red], startPoint: .leading, endPoint: .trailing) :
                           LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing)) :
                          LinearGradient(colors: [.orange, .yellow], startPoint: .leading, endPoint: .trailing)
                    )
            )
            .shadow(color: (manager.isTracking ? Color.blue : Color.orange).opacity(0.3), radius: 8, y: 4)
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
    
    // MARK: - Weekly Preview
    private var weeklyPreviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("이번 주")
                .font(.headline)
            
            HStack(spacing: 8) {
                ForEach(manager.getLast7DaysData(), id: \.0) { day, minutes, avgLux in
                    VStack(spacing: 6) {
                        ZStack(alignment: .bottom) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.gray.opacity(0.1))
                                .frame(width: 32, height: 80)
                            
                            RoundedRectangle(cornerRadius: 4)
                                .fill(
                                    minutes >= manager.settings.dailyGoalMinutes ?
                                    Color.orange : Color.orange.opacity(0.5)
                                )
                                .frame(
                                    width: 32,
                                    height: max(4, CGFloat(min(minutes, manager.settings.dailyGoalMinutes)) / CGFloat(max(manager.settings.dailyGoalMinutes, 1)) * 80)
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
                Rectangle().fill(Color.orange.opacity(0.5)).frame(width: 12, height: 3)
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

// MARK: - Lux Bar View
struct LuxBarView: View {
    let currentLux: Double
    let threshold: Double
    
    private var fillRatio: Double {
        // Log scale: 0 lux = 0, 100000 lux = 1.0
        guard currentLux > 0 else { return 0 }
        return min(log10(currentLux) / 5.0, 1.0) // log10(100000) = 5
    }
    
    private var thresholdRatio: Double {
        guard threshold > 0 else { return 0 }
        return min(log10(threshold) / 5.0, 1.0)
    }
    
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                // Background
                RoundedRectangle(cornerRadius: 6)
                    .fill(
                        LinearGradient(
                            colors: [.gray.opacity(0.2), .yellow.opacity(0.2), .orange.opacity(0.3), .red.opacity(0.3)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                
                // Fill
                RoundedRectangle(cornerRadius: 6)
                    .fill(
                        LinearGradient(
                            colors: [.yellow, .orange, .red],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geo.size.width * fillRatio)
                    .animation(.easeInOut(duration: 0.3), value: fillRatio)
                
                // Threshold line
                Rectangle()
                    .fill(Color.orange)
                    .frame(width: 2, height: geo.size.height + 8)
                    .offset(x: geo.size.width * thresholdRatio - 1)
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

import SwiftUI

struct SettingsView: View {
    @ObservedObject var manager: SunlightManager
    @ObservedObject var notificationManager: NotificationManager
    @State private var showingResetAlert = false
    
    var body: some View {
        NavigationStack {
            Form {
                // Goal Section
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("일일 목표")
                            Spacer()
                            Text("\(manager.settings.dailyGoalMinutes)분")
                                .foregroundColor(.orange).font(.headline)
                        }
                        Slider(
                            value: Binding(
                                get: { Double(manager.settings.dailyGoalMinutes) },
                                set: { manager.settings.dailyGoalMinutes = Int($0) }
                            ),
                            in: 10...120, step: 5
                        )
                        .tint(.orange)
                        HStack {
                            Text("10분").font(.caption2).foregroundColor(.secondary)
                            Spacer()
                            Text("120분").font(.caption2).foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Label("목표 설정", systemImage: "target")
                } footer: {
                    Text("전문가들은 하루 최소 15~30분의 자연광 노출을 권장합니다.")
                }
                
                // 조도 센서 설정
                Section {
                    Toggle(isOn: $manager.settings.autoTrackingEnabled) {
                        Label("자동 트래킹", systemImage: "camera.metering.spot")
                    }
                    .tint(.orange)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("실외 판정 기준")
                            Spacer()
                            Text("\(Int(manager.settings.outdoorThresholdLux)) Lux")
                                .foregroundColor(.cyan).font(.subheadline.bold())
                        }
                        Slider(
                            value: $manager.settings.outdoorThresholdLux,
                            in: 100...2000, step: 50
                        )
                        .tint(.cyan)
                        HStack {
                            Text("100 (흐림)").font(.caption2).foregroundColor(.secondary)
                            Spacer()
                            Text("2000 (맑음)").font(.caption2).foregroundColor(.secondary)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("햇빛 판정 기준")
                            Spacer()
                            Text("\(Int(manager.settings.sunlightThresholdLux)) Lux")
                                .foregroundColor(.orange).font(.subheadline.bold())
                        }
                        Slider(
                            value: $manager.settings.sunlightThresholdLux,
                            in: 500...5000, step: 100
                        )
                        .tint(.orange)
                        HStack {
                            Text("500").font(.caption2).foregroundColor(.secondary)
                            Spacer()
                            Text("5000").font(.caption2).foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Label("조도 센서", systemImage: "light.max")
                } footer: {
                    Text("실외 판정 기준 이상의 조도가 감지되면 자동으로 세션이 시작됩니다. 일반적으로 실외는 300~1000 Lux, 직사광선은 10,000 Lux 이상입니다.")
                }
                
                // Lux 참고표
                Section {
                    LuxReferenceRow(level: "어두운 실내", range: "< 50 Lux", emoji: "🌑")
                    LuxReferenceRow(level: "일반 실내", range: "50 ~ 300 Lux", emoji: "💡")
                    LuxReferenceRow(level: "흐린 날 / 그늘", range: "300 ~ 1,000 Lux", emoji: "☁️")
                    LuxReferenceRow(level: "실외 (맑음)", range: "1,000 ~ 10,000 Lux", emoji: "⛅")
                    LuxReferenceRow(level: "직사광선", range: "10,000 ~ 50,000 Lux", emoji: "☀️")
                    LuxReferenceRow(level: "한여름 정오", range: "50,000+ Lux", emoji: "🔆")
                } header: {
                    Label("조도 참고표", systemImage: "lightbulb")
                }
                
                // Notification Section
                Section {
                    Toggle(isOn: $manager.settings.reminderEnabled) {
                        Label("일일 리마인더", systemImage: "bell.fill")
                    }
                    .tint(.orange)
                    
                    if manager.settings.reminderEnabled {
                        DatePicker("알림 시간", selection: $manager.settings.reminderTime, displayedComponents: .hourAndMinute)
                    }
                    
                    Toggle(isOn: $manager.settings.notifyGoalAchieved) {
                        Label("목표 달성 알림", systemImage: "checkmark.circle.fill")
                    }
                    .tint(.orange)
                } header: {
                    Label("알림", systemImage: "bell")
                }
                
                // Info Section
                Section {
                    InfoRow(title: "카메라 기반 측정", detail: "후면 카메라의 ISO/노출 데이터로 주변 조도(Lux)를 추정합니다")
                    InfoRow(title: "자동 세션 감지", detail: "기준 이상 조도가 3회 연속 감지되면 세션이 자동 시작됩니다")
                    InfoRow(title: "배터리 절약", detail: "최저 해상도 카메라를 사용하여 배터리 소모를 최소화합니다")
                    InfoRow(title: "정확도", detail: "카메라 기반 추정값으로, 전문 조도계와 차이가 있을 수 있습니다")
                } header: {
                    Label("작동 원리", systemImage: "questionmark.circle")
                }
                
                // Data Section
                Section {
                    Button(role: .destructive) {
                        showingResetAlert = true
                    } label: {
                        Label("데이터 초기화", systemImage: "trash")
                    }
                } header: {
                    Label("데이터", systemImage: "externaldrive")
                }
                
                Section {
                    HStack {
                        Text("버전")
                        Spacer()
                        Text("2.0.0").foregroundColor(.secondary)
                    }
                } header: {
                    Label("정보", systemImage: "info")
                }
            }
            .navigationTitle("설정")
            .onChange(of: manager.settings.dailyGoalMinutes) { _, _ in manager.saveSettings() }
            .onChange(of: manager.settings.outdoorThresholdLux) { _, _ in manager.saveSettings() }
            .onChange(of: manager.settings.sunlightThresholdLux) { _, _ in manager.saveSettings() }
            .onChange(of: manager.settings.autoTrackingEnabled) { _, _ in manager.saveSettings() }
            .onChange(of: manager.settings.reminderEnabled) { _, newValue in
                if newValue {
                    notificationManager.requestAuthorization()
                    notificationManager.scheduleReminder(at: manager.settings.reminderTime)
                } else {
                    notificationManager.cancelAll()
                }
                manager.saveSettings()
            }
            .alert("데이터 초기화", isPresented: $showingResetAlert) {
                Button("취소", role: .cancel) {}
                Button("초기화", role: .destructive) {
                    manager.weeklyRecords = []
                    manager.todayRecord = SunlightRecord(goalMinutes: manager.settings.dailyGoalMinutes)
                    manager.saveRecords()
                }
            } message: {
                Text("모든 일조량 기록이 삭제됩니다. 이 작업은 되돌릴 수 없습니다.")
            }
        }
    }
}

struct LuxReferenceRow: View {
    let level: String
    let range: String
    let emoji: String
    
    var body: some View {
        HStack {
            Text(emoji).frame(width: 24)
            Text(level).font(.subheadline)
            Spacer()
            Text(range).font(.caption).foregroundColor(.secondary)
        }
    }
}

struct InfoRow: View {
    let title: String
    let detail: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.subheadline)
            Text(detail).font(.caption).foregroundColor(.secondary)
        }
        .padding(.vertical, 2)
    }
}

import SwiftUI

struct HistoryView: View {
    @ObservedObject var manager: SunlightManager
    @State private var selectedPeriod: Period = .week
    
    enum Period: String, CaseIterable {
        case week = "주간"
        case month = "월간"
    }
    
    private var filteredRecords: [SunlightRecord] {
        let calendar = Calendar.current
        let cutoff: Date
        switch selectedPeriod {
        case .week:
            cutoff = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        case .month:
            cutoff = calendar.date(byAdding: .month, value: -1, to: Date()) ?? Date()
        }
        return manager.weeklyRecords
            .filter { $0.date >= cutoff }
            .sorted { $0.date > $1.date }
    }
    
    private var totalMinutes: Int { filteredRecords.reduce(0) { $0 + $1.totalMinutes } }
    private var averageMinutes: Double {
        guard !filteredRecords.isEmpty else { return 0 }
        return Double(totalMinutes) / Double(filteredRecords.count)
    }
    private var goalDays: Int { filteredRecords.filter { $0.goalAchieved }.count }
    private var avgPeakLux: Double {
        let peaks = filteredRecords.map(\.peakLux).filter { $0 > 0 }
        guard !peaks.isEmpty else { return 0 }
        return peaks.reduce(0, +) / Double(peaks.count)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    Picker("기간", selection: $selectedPeriod) {
                        ForEach(Period.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 20)
                    
                    summarySection
                    chartSection
                    dailyRecordsSection
                }
                .padding(.bottom, 30)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("기록")
        }
    }
    
    // MARK: - Summary
    private var summarySection: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            SummaryCard2(title: "총 일조량", value: "\(totalMinutes)분", icon: "sun.max.fill", color: .orange)
            SummaryCard2(title: "일평균", value: "\(Int(averageMinutes))분", icon: "chart.bar.fill", color: .blue)
            SummaryCard2(title: "목표 달성", value: "\(goalDays)일", icon: "checkmark.seal.fill", color: .green)
            SummaryCard2(title: "평균 최고조도", value: avgPeakLux.luxFormatted + " lx", icon: "light.max", color: .yellow)
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Chart
    private var chartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("일별 일조량 & 조도")
                .font(.headline)
            
            let data = getChartData()
            
            if data.isEmpty {
                Text("아직 기록이 없습니다")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 150)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .bottom, spacing: 6) {
                        ForEach(data, id: \.date) { item in
                            VStack(spacing: 4) {
                                // 조도 표시
                                if item.peakLux > 0 {
                                    Text(item.peakLux.luxFormatted)
                                        .font(.system(size: 8))
                                        .foregroundColor(.orange.opacity(0.7))
                                }
                                
                                Text("\(item.minutes)")
                                    .font(.system(size: 9))
                                    .foregroundColor(.secondary)
                                
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(
                                        item.minutes >= manager.settings.dailyGoalMinutes ?
                                        Color.orange : Color.orange.opacity(0.4)
                                    )
                                    .frame(
                                        width: 24,
                                        height: max(4, CGFloat(item.minutes) / CGFloat(max(manager.settings.dailyGoalMinutes, 1)) * 100)
                                    )
                                
                                Text(item.dayLabel)
                                    .font(.system(size: 9))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .frame(minHeight: 160)
                    .padding(.horizontal, 4)
                }
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .padding(.horizontal, 20)
    }
    
    // MARK: - Daily Records
    private var dailyRecordsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("상세 기록")
                .font(.headline)
                .padding(.horizontal, 20)
            
            if filteredRecords.isEmpty {
                Text("기록이 없습니다")
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 20)
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(filteredRecords) { record in
                        DayRecordRow(record: record, goalMinutes: manager.settings.dailyGoalMinutes)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
    
    // MARK: - Helpers
    struct ChartItem {
        let date: Date
        let dayLabel: String
        let minutes: Int
        let peakLux: Double
    }
    
    private func getChartData() -> [ChartItem] {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "d"
        
        let days = selectedPeriod == .week ? 7 : 30
        var items: [ChartItem] = []
        
        for i in (0..<days).reversed() {
            let date = calendar.date(byAdding: .day, value: -i, to: Date()) ?? Date()
            let record = manager.weeklyRecords.first(where: { calendar.isDate($0.date, inSameDayAs: date) })
            items.append(ChartItem(
                date: date,
                dayLabel: formatter.string(from: date),
                minutes: record?.totalMinutes ?? 0,
                peakLux: record?.peakLux ?? 0
            ))
        }
        return items
    }
}

// MARK: - SummaryCard2
struct SummaryCard2: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 32)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.caption).foregroundColor(.secondary)
                Text(value).font(.headline)
            }
            Spacer()
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
}

// MARK: - DayRecordRow
struct DayRecordRow: View {
    let record: SunlightRecord
    let goalMinutes: Int
    
    var body: some View {
        HStack(spacing: 14) {
            VStack(spacing: 2) {
                let comps = Calendar.current.dateComponents([.day, .weekday], from: record.date)
                Text("\(comps.day ?? 0)")
                    .font(.title3.bold())
                let weekday = Calendar.current.shortWeekdaySymbols[(comps.weekday ?? 1) - 1]
                Text(weekday).font(.caption2).foregroundColor(.secondary)
            }
            .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("\(record.totalMinutes)분").font(.subheadline.bold())
                    
                    if record.peakLux > 0 {
                        Text("⚡\(record.peakLux.luxFormatted) lx")
                            .font(.caption2)
                            .foregroundColor(.orange)
                    }
                    
                    Spacer()
                    
                    if record.goalAchieved {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green).font(.caption)
                    }
                    Text("\(record.sessions.count)세션").font(.caption).foregroundColor(.secondary)
                }
                
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.gray.opacity(0.1)).frame(height: 6)
                        RoundedRectangle(cornerRadius: 3)
                            .fill(record.goalAchieved ? Color.orange : Color.orange.opacity(0.5))
                            .frame(width: geo.size.width * record.goalProgress, height: 6)
                    }
                }
                .frame(height: 6)
            }
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
}

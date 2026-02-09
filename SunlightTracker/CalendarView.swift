import SwiftUI

struct CalendarView: View {
    @ObservedObject var manager: SunlightManager
    @State private var selectedDate: Date = Date()
    @State private var showingMoodNote = false
    @State private var currentMonth: Date = Date()

    private var calendar: Calendar { Calendar.current }

    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy년 M월"
        return formatter.string(from: currentMonth)
    }

    private var daysInMonth: [Date] {
        guard let range = calendar.range(of: .day, in: .month, for: currentMonth),
              let firstDay = calendar.date(from: calendar.dateComponents([.year, .month], from: currentMonth)) else {
            return []
        }

        return range.compactMap { day -> Date? in
            calendar.date(byAdding: .day, value: day - 1, to: firstDay)
        }
    }

    private var paddingDays: Int {
        guard let firstDay = daysInMonth.first else { return 0 }
        let weekday = calendar.component(.weekday, from: firstDay)
        return (weekday + 5) % 7 // 월요일 시작 기준
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 월 네비게이션
                    monthNavigation

                    // 캘린더
                    calendarGrid

                    // 선택된 날짜 상세 정보
                    selectedDayDetail

                    // 월간 요약 통계
                    monthSummary
                }
                .padding(.bottom, 30)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("캘린더")
        }
        .sheet(isPresented: $showingMoodNote) {
            MoodNoteSheet(manager: manager, date: selectedDate, isPresented: $showingMoodNote)
        }
    }

    // MARK: - Month Navigation
    private var monthNavigation: some View {
        HStack {
            Button(action: { changeMonth(by: -1) }) {
                Image(systemName: "chevron.left")
                    .font(.title3)
                    .foregroundColor(.primary)
            }

            Spacer()

            Text(monthYearString)
                .font(.title2.bold())

            Spacer()

            Button(action: { changeMonth(by: 1) }) {
                Image(systemName: "chevron.right")
                    .font(.title3)
                    .foregroundColor(.primary)
            }
            .disabled(calendar.isDate(currentMonth, equalTo: Date(), toGranularity: .month))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }

    // MARK: - Calendar Grid
    private var calendarGrid: some View {
        VStack(spacing: 12) {
            // 요일 헤더
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                ForEach(["월", "화", "수", "목", "금", "토", "일"], id: \.self) { day in
                    Text(day)
                        .font(.caption.bold())
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }

            // 날짜 그리드
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 12) {
                // 빈 공간
                ForEach(0..<paddingDays, id: \.self) { _ in
                    Color.clear.frame(height: 70)
                }

                // 날짜
                ForEach(daysInMonth, id: \.self) { date in
                    DayCell(
                        date: date,
                        isToday: calendar.isDateInToday(date),
                        isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                        record: manager.weeklyRecords.first(where: { calendar.isDate($0.date, inSameDayAs: date) })
                    )
                    .onTapGesture {
                        selectedDate = date
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .padding(.horizontal, 20)
    }

    // MARK: - Selected Day Detail
    private var selectedDayDetail: some View {
        let record = manager.weeklyRecords.first(where: { calendar.isDate($0.date, inSameDayAs: selectedDate) })

        return VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(selectedDate.shortDateString)
                        .font(.headline)
                    if selectedDate.isToday {
                        Text("오늘")
                            .font(.caption)
                            .foregroundColor(.green)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(Color.green.opacity(0.15)))
                    }
                }

                Spacer()

                Button(action: {
                    showingMoodNote = true
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "square.and.pencil")
                        Text(record?.mood != nil || record?.note != nil ? "수정" : "기록")
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                }
            }

            if let record = record {
                // 기분 & 메모
                if let mood = record.mood {
                    HStack(spacing: 8) {
                        Text(mood.rawValue)
                            .font(.title)
                        Text(mood.description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                }

                if let note = record.note, !note.isEmpty {
                    Text(note)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.tertiarySystemGroupedBackground))
                        .cornerRadius(8)
                }

                Divider()

                // 햇빛 기록
                HStack(spacing: 24) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("일조량")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        HStack(spacing: 4) {
                            Image(systemName: "sun.max.fill")
                                .font(.caption)
                                .foregroundColor(.orange)
                            Text("\(record.totalMinutes)분")
                                .font(.title3.bold())
                        }
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("세션")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(record.sessions.count)회")
                            .font(.title3.bold())
                    }

                    if record.peakLux > 0 {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("최고 조도")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            HStack(spacing: 4) {
                                Image(systemName: "light.max")
                                    .font(.caption)
                                    .foregroundColor(.yellow)
                                Text(record.peakLux.luxFormatted + " lx")
                                    .font(.title3.bold())
                            }
                        }
                    }
                }

                // 진행도 바
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.2))

                        RoundedRectangle(cornerRadius: 4)
                            .fill(record.goalAchieved ? Color(red: 0.3, green: 0.7, blue: 0.2) : Color.orange)
                            .frame(width: geo.size.width * record.goalProgress)
                    }
                }
                .frame(height: 8)

                if record.goalAchieved {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("목표 달성!")
                            .font(.caption.bold())
                            .foregroundColor(.green)
                    }
                }
            } else {
                Text("이 날의 기록이 없습니다")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 30)
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .padding(.horizontal, 20)
    }

    // MARK: - Month Summary
    private var monthSummary: some View {
        let monthRecords = manager.weeklyRecords.filter {
            calendar.isDate($0.date, equalTo: currentMonth, toGranularity: .month)
        }

        let totalMinutes = monthRecords.reduce(0) { $0 + $1.totalMinutes }
        let goalDays = monthRecords.filter { $0.goalAchieved }.count
        let avgMinutes = monthRecords.isEmpty ? 0 : Double(totalMinutes) / Double(monthRecords.count)

        return VStack(alignment: .leading, spacing: 12) {
            Text("이번 달 요약")
                .font(.headline)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                SummaryCard2(title: "총 일조량", value: "\(totalMinutes)분", icon: "sun.max.fill", color: .orange)
                SummaryCard2(title: "일평균", value: "\(Int(avgMinutes))분", icon: "chart.bar.fill", color: .blue)
                SummaryCard2(title: "목표 달성", value: "\(goalDays)일", icon: "checkmark.seal.fill", color: .green)
                SummaryCard2(title: "기록 일수", value: "\(monthRecords.count)일", icon: "calendar", color: .purple)
            }
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Helpers
    private func changeMonth(by value: Int) {
        if let newMonth = calendar.date(byAdding: .month, value: value, to: currentMonth) {
            currentMonth = newMonth
        }
    }
}

// MARK: - Day Cell
struct DayCell: View {
    let date: Date
    let isToday: Bool
    let isSelected: Bool
    let record: SunlightRecord?

    private var day: Int {
        Calendar.current.component(.day, from: date)
    }

    var body: some View {
        VStack(spacing: 4) {
            // 날짜
            Text("\(day)")
                .font(.system(size: 14, weight: isToday ? .bold : .regular))
                .foregroundColor(isToday ? .white : (isSelected ? .white : .primary))

            // 기분 이모지
            if let mood = record?.mood {
                Text(mood.rawValue)
                    .font(.system(size: 16))
            } else if record != nil && record!.totalMinutes > 0 {
                Circle()
                    .fill(record!.goalAchieved ? Color.green : Color.orange)
                    .frame(width: 4, height: 4)
            } else {
                Spacer().frame(height: 18)
            }

            // 일조량 (작은 텍스트)
            if let minutes = record?.totalMinutes, minutes > 0 {
                Text("\(minutes)분")
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 70)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isSelected ? Color.blue : (isToday ? Color.green : Color.clear))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isToday && !isSelected ? Color.green : Color.clear, lineWidth: 2)
        )
    }
}

// MARK: - Mood & Note Sheet
struct MoodNoteSheet: View {
    @ObservedObject var manager: SunlightManager
    let date: Date
    @Binding var isPresented: Bool

    @State private var selectedMood: DailyMood?
    @State private var noteText: String = ""

    private var record: SunlightRecord? {
        manager.weeklyRecords.first(where: { Calendar.current.isDate($0.date, inSameDayAs: date) })
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text(date.shortDateString)
                        .font(.headline)
                } header: {
                    Text("날짜")
                }

                Section {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 16) {
                        ForEach(DailyMood.allCases, id: \.self) { mood in
                            VStack(spacing: 4) {
                                Text(mood.rawValue)
                                    .font(.system(size: 32))
                                    .padding(8)
                                    .background(
                                        Circle()
                                            .fill(selectedMood == mood ? Color.blue.opacity(0.2) : Color.clear)
                                    )
                                    .overlay(
                                        Circle()
                                            .stroke(selectedMood == mood ? Color.blue : Color.clear, lineWidth: 2)
                                    )
                                    .onTapGesture {
                                        selectedMood = mood
                                    }

                                Text(mood.description)
                                    .font(.system(size: 9))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                } header: {
                    Text("오늘의 기분")
                }

                Section {
                    TextEditor(text: $noteText)
                        .frame(minHeight: 100)
                } header: {
                    Text("한마디 메모")
                } footer: {
                    Text("오늘 하루를 짧게 기록해보세요")
                }
            }
            .navigationTitle("기록하기")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") {
                        isPresented = false
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("저장") {
                        saveRecord()
                        isPresented = false
                    }
                }
            }
            .onAppear {
                selectedMood = record?.mood
                noteText = record?.note ?? ""
            }
        }
    }

    private func saveRecord() {
        if let mood = selectedMood {
            manager.updateMood(for: date, mood: mood)
        }

        if !noteText.isEmpty {
            manager.updateNote(for: date, note: noteText)
        } else if noteText.isEmpty && record?.note != nil {
            manager.updateNote(for: date, note: nil)
        }
    }
}

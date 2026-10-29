import SwiftUI

struct CalendarView: View {
    @ObservedObject var manager: SunlightManager
    @State private var selectedDate: Date = Date()
    @State private var showingMoodNote = false
    @State private var currentMonth: Date = Date()

    private var calendar: Calendar { Calendar.current }

    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.setLocalizedDateFormatFromTemplate("yyyyMMMM")
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
            .accessibilityLabel(Text("이전 달"))

            Spacer()

            Text(monthYearString)
                .font(.title2.bold())
                .accessibilityAddTraits(.isHeader)

            Spacer()

            Button(action: { changeMonth(by: 1) }) {
                Image(systemName: "chevron.right")
                    .font(.title3)
                    .foregroundColor(.primary)
            }
            .accessibilityLabel(Text("다음 달"))
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
                ForEach([String(localized: "월"), String(localized: "화"), String(localized: "수"), String(localized: "목"), String(localized: "금"), String(localized: "토"), String(localized: "일")], id: \.self) { day in
                    Text(day)
                        .font(.caption.bold())
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            .accessibilityHidden(true)  // 요일은 날짜 칸마다 읽어 준다

            // 날짜 그리드
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 12) {
                // 빈 공간
                ForEach(0..<paddingDays, id: \.self) { _ in
                    Color.clear.frame(height: 70)
                }

                // 날짜
                ForEach(daysInMonth, id: \.self) { date in
                    Button {
                        selectedDate = date
                    } label: {
                        DayCell(
                            date: date,
                            isToday: calendar.isDateInToday(date),
                            isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                            record: manager.weeklyRecords.first(where: { calendar.isDate($0.date, inSameDayAs: date) })
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        // 7칸 달력은 너무 커지면 깨진다. 자세한 내용은 아래 상세 카드가 끝까지 커진다
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
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
                            .accessibilityHidden(true)
                        Text(record?.mood != nil || record?.note != nil ? String(localized: "수정") : String(localized: "기록"))
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
                            .accessibilityHidden(true)
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
                                .accessibilityHidden(true)
                            Text("\(record.totalMinutes)분")
                                .font(.title3.bold())
                        }
                    }
                    .accessibilityElement(children: .combine)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("세션")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(record.sessions.count)회")
                            .font(.title3.bold())
                    }
                    .accessibilityElement(children: .combine)

                    if record.peakLux > 0 {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("최고 조도")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            HStack(spacing: 4) {
                                Image(systemName: "light.max")
                                    .font(.caption)
                                    .foregroundColor(.yellow)
                                    .accessibilityHidden(true)
                                Text(record.peakLux.luxFormatted + " lx")
                                    .font(.title3.bold())
                            }
                        }
                        .accessibilityElement(children: .combine)
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
                .accessibilityHidden(true)

                if record.goalAchieved {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .accessibilityHidden(true)
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
                .accessibilityAddTraits(.isHeader)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                SummaryCard2(title: String(localized: "총 일조량"), value: String(localized: "\(totalMinutes)분"), icon: "sun.max.fill", color: .orange)
                SummaryCard2(title: String(localized: "일평균"), value: String(localized: "\(Int(avgMinutes))분"), icon: "chart.bar.fill", color: .blue)
                SummaryCard2(title: String(localized: "목표 달성"), value: String(localized: "\(goalDays)일"), icon: "checkmark.seal.fill", color: .green)
                SummaryCard2(title: String(localized: "기록 일수"), value: String(localized: "\(monthRecords.count)일"), icon: "calendar", color: .purple)
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
                .font(.subheadline.weight(isToday ? .bold : .regular))
                .foregroundColor(isToday ? .white : (isSelected ? .white : .primary))

            // 기분 이모지
            if let mood = record?.mood {
                Text(mood.rawValue)
                    .font(.callout)
            } else if let record, record.totalMinutes > 0 {
                // 색만으로 구별하지 않게: 달성은 꽉 찬 점, 미달은 빈 고리
                Group {
                    if record.goalAchieved {
                        Circle().fill(Color.green)
                    } else {
                        Circle().strokeBorder(Color.orange, lineWidth: 1.5)
                    }
                }
                .frame(width: 6, height: 6)
            } else {
                Spacer().frame(height: 18)
            }

            // 일조량 (작은 텍스트)
            if let minutes = record?.totalMinutes, minutes > 0 {
                Text("\(minutes)분")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 70)
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(date.formatted(date: .complete, time: .omitted)))
        .accessibilityValue(accessibilityValue)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
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

extension DayCell {
    /// 이 날 기록을 한 문장으로: "오늘, 30분, 목표 달성, 좋음"
    private var accessibilityValue: Text {
        var parts: [Text] = []
        if isToday { parts.append(Text("오늘")) }
        if let record, record.totalMinutes > 0 {
            parts.append(Text("\(record.totalMinutes)분"))
            if record.goalAchieved { parts.append(Text("목표 달성")) }
        }
        if let mood = record?.mood { parts.append(Text(mood.description)) }
        return parts.dropFirst().reduce(parts.first ?? Text(verbatim: "")) { $0 + Text(verbatim: ", ") + $1 }
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
                            Button {
                                selectedMood = mood
                            } label: {
                                VStack(spacing: 4) {
                                    Text(mood.rawValue)
                                        .font(.largeTitle)
                                        .padding(8)
                                        .background(
                                            Circle()
                                                .fill(selectedMood == mood ? Color.blue.opacity(0.2) : Color.clear)
                                        )
                                        .overlay(
                                            Circle()
                                                .stroke(selectedMood == mood ? Color.blue : Color.clear, lineWidth: 2)
                                        )

                                    Text(mood.description)
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                        .minimumScaleFactor(0.7)
                                }
                            }
                            .buttonStyle(.plain)
                            .accessibilityElement(children: .ignore)
                            .accessibilityLabel(Text(mood.description))
                            .accessibilityAddTraits(selectedMood == mood ? .isSelected : [])
                        }
                    }
                    .padding(.vertical, 8)
                    .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
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

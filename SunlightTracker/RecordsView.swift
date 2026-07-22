import SwiftUI

/// 캘린더 + 통계를 하나로 합친 기록 탭
struct RecordsView: View {
    @ObservedObject var manager: SunlightManager
    @State private var mode: RecordMode = .calendar

    enum RecordMode: String, CaseIterable {
        case calendar = "📅 캘린더"
        case stats = "📊 통계"
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("보기", selection: $mode) {
                    ForEach(RecordMode.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 4)
                .background(Color(.systemGroupedBackground))

                switch mode {
                case .calendar:
                    CalendarView(manager: manager)
                case .stats:
                    HistoryView(manager: manager)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("기록")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    RecordsView(manager: SunlightManager())
}

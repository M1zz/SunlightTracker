import SwiftUI

/// 캘린더 + 통계를 하나로 합친 기록 탭
struct RecordsView: View {
    @ObservedObject var manager: SunlightManager
    /// 스토어 스크린샷용: Debug 빌드에서만 `-ScreenshotRecordMode stats` 로 통계부터 연다.
    @State private var mode: RecordMode = {
        #if DEBUG
        return UserDefaults.standard.string(forKey: "ScreenshotRecordMode") == "stats" ? .stats : .calendar
        #else
        return .calendar
        #endif
    }()

    enum RecordMode: String, CaseIterable {
        case calendar = "📅 캘린더"
        case stats = "📊 통계"
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("보기", selection: $mode) {
                    ForEach(RecordMode.allCases, id: \.self) { Text(LocalizedStringKey($0.rawValue)).tag($0) }
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
            .navigationTitle(String(localized: "tab.records", defaultValue: "기록"))
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    RecordsView(manager: SunlightManager())
}

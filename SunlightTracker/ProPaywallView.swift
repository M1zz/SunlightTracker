//
//  ProPaywallView.swift
//  SunlightTracker
//
//  햇빛바라기 Pro 를 파는 한 장, 구독 졸업 시트, 설정의 Pro 줄.
//
//  **무료인 것을 먼저 말한다.** 비교표의 위 일곱 줄은 무료 · Pro 모두 ✓ 다. 이 화면은
//  "안 사면 못 쓴다"가 아니라 "햇빛 모으기는 전부 무료이고, 앱 밖에서 보이는 것만 값을 받는다"는 말이다.
//
//  고르는 길: 연 구독(기본) · 평생, 펼치면 주 · 월. 첫 해 할인(App Store 첫 구독 할인)과
//  "연 구독 N년치" 한 줄은 `LeeoTermPicker` 가 알아서 보인다.
//  스토어에서 불러온 상품만 단추가 된다 — 아직 없는 상품은 서지 않는다.
//

import SwiftUI
import StoreKit
import LeeoKit

struct ProPaywallView: View {
    let moment: ProMoment

    @ObservedObject private var pro = SunflowerPro.shared
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    /// 결제 시트를 **이 페이월이 떠 있는 창**에 띄운다.
    @Environment(\.purchase) private var purchaseAction

    @State private var term: LeeoPlanTerm
    /// 펼쳐서 고른 주 · 월 구독. 고르면 연 / 평생 대신 이것을 산다.
    @State private var shortPlanID: String?
    @State private var loadingProducts = true

    init(moment: ProMoment) {
        self.moment = moment
        _term = State(initialValue: moment.defaultTerm)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header
                    comparison
                    if pro.hasPro {
                        Label("햇빛바라기 Pro를 쓰고 있어요. 고마워요.", systemImage: "checkmark.seal.fill")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(.orange)
                    } else {
                        plans
                    }
                    if let message = pro.failureMessage, !pro.products.isEmpty {
                        Label(message, systemImage: "exclamationmark.triangle")
                            .font(.body)
                            .foregroundStyle(.orange)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    legal
                }
                .padding(24)
                .frame(maxWidth: 640)
                .frame(maxWidth: .infinity)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("햇빛바라기 Pro")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("나중에", systemImage: "xmark") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("구매 복원") {
                        Task {
                            await pro.restore()
                            if pro.hasPro { dismiss() }
                        }
                    }
                    .disabled(pro.isWorking)
                }
            }
            .task { await loadPlans() }
        }
        .tint(.orange)
    }

    // MARK: 머리

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let lead = momentLead {
                Text(lead)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.orange)
                    .fixedSize(horizontal: false, vertical: true)
            }
            ProPreviewCard(moment: moment)
            Text("햇빛바라기 Pro")
                .font(.largeTitle.bold())
                .accessibilityAddTraits(.isHeader)
            Text("앱을 열지 않아도 해바라기가 먼저 불러요. 연 구독이나 평생 중에 고르세요.")
                .font(.body)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    /// 막혀서 들어왔으면 무엇이 막혔는지, 쌓아 온 것이 있으면 그것을 먼저 말한다.
    private var momentLead: String? {
        switch moment {
        case .widget:
            String(localized: "홈 화면 위젯은 Pro에서 열려요.", comment: "Paywall lead: opened from a locked Home Screen widget")
        case .liveActivity:
            String(localized: "밖에 있는 동안 잠금화면에 모은 시간이 흘러요.", comment: "Paywall lead: after the first sunlight session, previews the Lock Screen Live Activity")
        case .monthlyStats:
            String(localized: "월간 통계는 Pro에서 열려요. 지난 기록은 캘린더에서 그대로 볼 수 있어요.", comment: "Paywall lead: picked Monthly in stats. Past days stay visible in the calendar")
        case .weekGoal(let minutes):
            String(localized: "이번 주 햇빛 \(minutes)분을 모았어요", comment: "Paywall lead: on the day the daily goal is met for the 7th time. %lld = minutes of sunlight this week")
        case .settings:
            nil
        }
    }

    // MARK: 비교표

    private var comparison: some View {
        Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 10) {
            GridRow {
                Text("기능")
                Text("무료").gridColumnAlignment(.center)
                Text(verbatim: "Pro").gridColumnAlignment(.center)
            }
            .font(.body.weight(.semibold))
            .foregroundStyle(.secondary)
            .accessibilityHidden(true)
            Divider()
            freeRow("햇빛 자동 측정 · 기준 조정")
            freeRow("해바라기 키우기")
            freeRow("하루 목표 · 알림")
            freeRow("자외선 · 선크림 안내")
            freeRow("캘린더 기분 · 한마디")
            freeRow("친구와 함께")
            freeRow("주간 통계")
            proRow("월간 통계", gate: .monthlyStats)
            proRow("홈 화면 위젯 5종", gate: .widgets)
            proRow("잠금화면 · 다이나믹 아일랜드", gate: .liveActivity)
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func freeRow(_ title: LocalizedStringKey) -> some View {
        GridRow {
            Text(title).fixedSize(horizontal: false, vertical: true)
            check
            check
        }
        .font(.body)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(title))
        .accessibilityValue(Text("무료"))
    }

    private func proRow(_ title: LocalizedStringKey, gate: ProGate) -> some View {
        let highlighted = gate == moment.gate
        return GridRow {
            Text(title).fixedSize(horizontal: false, vertical: true)
            Image(systemName: "minus")
                .foregroundStyle(.secondary)
                .frame(minWidth: 44)
            check
        }
        .font(.body.weight(highlighted ? .semibold : .regular))
        .foregroundStyle(highlighted ? Color.orange : .primary)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(title))
        .accessibilityValue(Text("Pro에서 열려요"))
    }

    private var check: some View {
        Image(systemName: "checkmark")
            .font(.body.weight(.bold))
            .foregroundStyle(.orange)
            .frame(minWidth: 44)
    }

    // MARK: 요금제

    @ViewBuilder
    private var plans: some View {
        let yearly = pro.product(ProProduct.yearly)
        let lifetime = pro.product(ProProduct.lifetime)
        if yearly == nil && lifetime == nil {
            plansStatus
        } else {
            VStack(alignment: .leading, spacing: 12) {
                LeeoTermPicker(term: Binding(get: { term }, set: { term = $0; shortPlanID = nil }),
                               yearly: yearly, lifetime: lifetime)
                    .opacity(shortPlanID == nil ? 1 : 0.5)
                shortPlans
                buyButton
            }
        }
    }

    /// 주 · 월 구독. 연 구독이 기본이라 펼쳐야 보인다. 불러온 상품만 줄이 선다.
    @ViewBuilder
    private var shortPlans: some View {
        let short = [pro.product(ProProduct.monthly), pro.product(ProProduct.weekly)].compactMap { $0 }
        if !short.isEmpty {
            DisclosureGroup("주 · 월 구독 보기") {
                VStack(spacing: 4) {
                    ForEach(short, id: \.id) { shortPlanRow($0) }
                }
                .padding(.top, 6)
            }
            .font(.body)
        }
    }

    private func shortPlanRow(_ product: Product) -> some View {
        let selected = shortPlanID == product.id
        let title = product.id == ProProduct.weekly
            ? String(localized: "주 구독 · \(product.displayPrice) / 주", comment: "Paywall: weekly plan row. %@ = price")
            : String(localized: "월 구독 · \(product.displayPrice) / 월", comment: "Paywall: monthly plan row. %@ = price")
        return Button {
            shortPlanID = selected ? nil : product.id
        } label: {
            HStack {
                Text(title).foregroundStyle(.primary)
                Spacer()
                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(selected ? Color.orange : .secondary)
                    .accessibilityHidden(true)
            }
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    /// 지금 고른 상품.
    private var chosen: Product? {
        if let shortPlanID { return pro.product(shortPlanID) }
        return pro.product(term == .yearly ? ProProduct.yearly : ProProduct.lifetime)
    }

    private var buyTitle: String {
        switch shortPlanID {
        case ProProduct.weekly?:  String(localized: "주 구독 시작")
        case ProProduct.monthly?: String(localized: "월 구독 시작")
        default: term == .yearly ? String(localized: "연 구독 시작") : String(localized: "평생으로 사기")
        }
    }

    private var buyButton: some View {
        Button {
            guard let chosen else { return }
            Task {
                await pro.purchase(chosen, using: purchaseAction)
                if pro.hasPro { dismiss() }
            }
        } label: {
            Group {
                if pro.isWorking {
                    ProgressView().tint(.white)
                } else {
                    Text(buyTitle).font(.headline)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 32)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .disabled(pro.isWorking || chosen == nil)
    }

    @ViewBuilder
    private var plansStatus: some View {
        if loadingProducts {
            HStack(spacing: 10) {
                ProgressView()
                Text("요금제를 불러오는 중…").font(.body).foregroundStyle(.secondary)
            }
        } else {
            // 한 번 실패하면 죽은 단추로 남지 않게, 그 자리에서 다시 청한다.
            VStack(alignment: .leading, spacing: 10) {
                Text("요금제를 불러오지 못했어요. 인터넷 연결을 확인하고 다시 불러와 주세요.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                Button {
                    Task { await loadPlans() }
                } label: {
                    Label("다시 불러오기", systemImage: "arrow.clockwise").font(.body.weight(.semibold))
                }
                .buttonStyle(.bordered)
            }
        }
    }

    /// 첫 조회가 비어 오면 한 번 더 청한다. 샌드박스(심사 환경)는 첫 조회가 빈손으로 오는 일이 잦다.
    private func loadPlans() async {
        loadingProducts = true
        await pro.loadProducts()
        if pro.products.isEmpty {
            try? await Task.sleep(for: .seconds(1.5))
            await pro.loadProducts()
        }
        loadingProducts = false
    }

    // MARK: 약관 (구독을 파는 앱의 심사 필수 항목)

    private var legal: some View {
        VStack(alignment: .leading, spacing: 10) {
            if pro.products.contains(where: { $0.subscription != nil }) {
                Text("구독은 기간이 끝나기 24시간 전까지 해지하지 않으면 같은 요금으로 자동 갱신되며, Apple 계정으로 결제돼요. 처음 연 구독을 시작하면 첫 해는 할인된 값으로 결제되고, 그 뒤에는 정가로 갱신돼요. 해지와 관리는 App Store 계정 설정에서 할 수 있어요. 평생은 구독이 아니라 한 번 결제예요.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            HStack(spacing: 20) {
                if let terms = SunlightTrackerSpec.monetization.subscriptionTermsURL {
                    Button("이용약관") { openURL(terms) }
                }
                Button("개인정보 처리방침") { openURL(SunlightTrackerSpec.legal.privacyURL) }
            }
            .font(.body)
        }
    }
}

// MARK: - 미리보기

/// 사기 전에 무엇이 생기는지 그림으로 보인다. 잠금화면 현황 · 홈 화면 위젯을 흉내 낸 작은 카드.
private struct ProPreviewCard: View {
    let moment: ProMoment
    @ObservedObject private var manager = SunlightManager.shared

    var body: some View {
        switch moment {
        case .liveActivity:
            lockScreen
        case .widget, .weekGoal:
            homeWidget
        case .monthlyStats, .settings:
            EmptyView()
        }
    }

    /// 잠금화면 실시간 현황: 해 · 모은 분 · 배터리.
    private var lockScreen: some View {
        let minutes = max(manager.todayRecord.totalMinutes, 1)
        return HStack(spacing: 14) {
            Image(systemName: "sun.max.fill")
                .font(.title)
                .foregroundStyle(.yellow)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
                Text("햇빛 받는 중")
                    .font(.headline)
                Text("\(minutes)분")
                    .font(.title2.bold().monospacedDigit())
            }
            Spacer(minLength: 8)
            Image(systemName: "battery.75percent")
                .font(.title2)
                .foregroundStyle(.green)
                .accessibilityHidden(true)
        }
        .foregroundStyle(.white)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(LinearGradient(colors: [Color(red: 0.12, green: 0.14, blue: 0.22), Color(red: 0.25, green: 0.2, blue: 0.12)],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
        )
        .accessibilityElement(children: .combine)
    }

    /// 홈 화면 작은 위젯: 해바라기 · 오늘 진행도.
    private var homeWidget: some View {
        let goal = max(manager.settings.dailyGoalMinutes, 1)
        let today = manager.todayRecord.totalMinutes
        return HStack(spacing: 16) {
            VStack(spacing: 6) {
                Text(verbatim: "🌻")
                    .font(.system(size: 44))
                    .accessibilityHidden(true)
                ProgressView(value: min(Double(today) / Double(goal), 1))
                    .tint(.orange)
                Text("\(today) / \(goal)분")
                    .font(.headline.monospacedDigit())
            }
            .padding(14)
            .frame(width: 150, height: 150)
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 26, style: .continuous))
            .shadow(color: .black.opacity(0.08), radius: 8, y: 2)
            Text("앱을 열지 않아도 홈 화면의 해바라기가 오늘 햇빛을 알려 줘요.")
                .font(.body)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - 구독 졸업

/// 구독 중인 사람에게 평생으로 옮겨 갈 값을 보인다. 사면 구독 관리 화면으로 해지를 돕는다.
struct ProGraduationSheet: View {
    @ObservedObject private var pro = SunflowerPro.shared

    var body: some View {
        LeeoGraduationOfferView(graduate: pro.product(ProProduct.graduate)) {
            await pro.refreshEntitlements()
        }
        .task { if pro.product(ProProduct.graduate) == nil { await pro.loadProducts() } }
    }
}

// MARK: - 설정의 Pro 줄

/// 설정 ▸ 햇빛바라기 Pro. 무료면 페이월로, 구독 중이면 구독 관리와 '평생으로 바꾸기', 복원은 늘.
struct ProSettingsSection: View {
    @ObservedObject private var pro = SunflowerPro.shared
    @State private var showGraduation = false
    @State private var showManage = false
    @State private var restoreMessage: String?

    var body: some View {
        Section {
            if !pro.hasPro {
                Button { pro.present(.settings) } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Label("햇빛바라기 Pro", systemImage: "sparkles")
                            .font(.body.weight(.semibold))
                        Text("홈 화면 위젯 · 잠금화면 실시간 현황 · 월간 통계")
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            } else if pro.ownsLifetime {
                Label("햇빛바라기 Pro 평생 사용 중", systemImage: "checkmark.seal.fill")
            } else if pro.subscription != nil {
                Label("햇빛바라기 Pro 구독 중", systemImage: "checkmark.seal.fill")
                Button { showManage = true } label: {
                    Label("구독 관리", systemImage: "creditcard")
                }
                Button { showGraduation = true } label: {
                    Label(LeeoLadderText.switchToLifetimeEntry, systemImage: "graduationcap")
                }
            } else {
                // 페이월 전에 설치한 사람 · 가족 공유로 받은 사람.
                Label("햇빛바라기 Pro 사용 중", systemImage: "checkmark.seal.fill")
            }
            Button {
                Task {
                    await pro.restore()
                    restoreMessage = pro.hasPro ? nil : pro.failureMessage
                }
            } label: {
                Label("구매 복원", systemImage: "arrow.clockwise")
            }
            .disabled(pro.isWorking)
        } header: {
            Label("햇빛바라기 Pro", systemImage: "sparkles")
        } footer: {
            if let restoreMessage { Text(restoreMessage) }
        }
        .sheet(isPresented: $showGraduation) { ProGraduationSheet() }
        .manageSubscriptionsSheet(isPresented: $showManage)
    }
}

//
//  SunflowerPro.swift
//  SunlightTracker
//
//  햇빛바라기 Pro — 무료 · Pro 두 칸. **속은 전부 LeeoKit 의 `LeeoStore` 다.**
//
//  햇빛을 재고, 해바라기를 키우고, 목표를 채우고, 친구와 함께 받는 것은 끝까지 무료다.
//  앱을 열지 않아도 해바라기가 보이는 셋(홈 화면 위젯 · 잠금화면 실시간 현황 · 월간 통계)만 Pro 다.
//
//  이 파일이 정하는 것:
//   · 상품 ID (`ProProduct`) — App Store Connect · Products.storekit 과 같아야 한다.
//   · 지금 열려 있는가 (`SunflowerPro.isOpen`) — 위젯에도 App Group 으로 같은 답을 비춘다.
//   · 페이월을 띄울 순간 (`ProMoment`)
//
//  ⚠️ 상품 로드 · 구매 · 복원 · 거래 리스너(다른 기기, 가족 공유, 환불, 만료)는 LeeoStore 안에 있다.
//     여기서 StoreKit 을 직접 쥐지 않는다.
//

import Foundation
import Combine
import StoreKit
import SwiftUI
import WidgetKit
import LeeoKit

// MARK: - 상품

/// App Store Connect · Products.storekit 과의 계약 — 한 번 정하면 바꾸지 않는다.
/// 주 · 월 · 연 구독은 구독 그룹 "Sunny Sunflower Pro" 하나에 둔다.
enum ProProduct {
    private static let base = "com.leeo.sunflower.pro"
    static let weekly   = base + ".weekly"
    static let monthly  = base + ".monthly"
    static let yearly   = base + ".yearly"
    static let lifetime = base + ".lifetime"
    /// 구독 졸업 — 구독 중인 사람에게만 보이는 평생가.
    static let graduate = base + ".graduate"

    static let subscriptions: Set<String> = [weekly, monthly, yearly]
    static let lifetimes: Set<String> = [lifetime, graduate]

    /// 불러올 순서. 팁 상품은 여기 넣지 않는다 — 팁은 아무것도 열지 않는다.
    static let all: [String] = [yearly, lifetime, monthly, weekly, graduate]
}

/// Pro 에서만 열리는 것 (계약의 게이트 선언과 같은 이름).
enum ProGate: String, CaseIterable {
    case widgets, liveActivity, monthlyStats
}

// MARK: - 페이월을 띄울 순간

/// 어디서 페이월이 떴는가. 머리 한 줄 · 미리보기 · 비교표 강조 · 기본으로 고를 길이 여기서 정해진다.
enum ProMoment: Identifiable, Equatable {
    /// 잠긴 위젯을 눌렀다.
    case widget
    /// 첫 햇빛 세션이 끝났다 — 잠금화면 실시간 현황 미리보기.
    case liveActivity
    /// 기록 ▸ 통계에서 '월간' 을 골랐다.
    case monthlyStats
    /// 하루 목표를 처음 일곱 번 채운 날. 이번 주 모은 분.
    case weekGoal(minutes: Int)
    /// 설정의 Pro 줄.
    case settings

    var id: String {
        switch self {
        case .widget: "widget"
        case .liveActivity: "liveActivity"
        case .monthlyStats: "monthlyStats"
        case .weekGoal: "weekGoal"
        case .settings: "settings"
        }
    }

    /// 비교표에서 강조할 줄.
    var gate: ProGate? {
        switch self {
        case .widget, .weekGoal: .widgets
        case .liveActivity: .liveActivity
        case .monthlyStats: .monthlyStats
        case .settings: nil
        }
    }

    /// 매일 쓰는 잠금화면 현황은 평생이 맞고, 나머지는 연 구독부터 보인다.
    var defaultTerm: LeeoPlanTerm { self == .liveActivity ? .lifetime : .yearly }
}

// MARK: - 권한

@MainActor
final class SunflowerPro: ObservableObject {

    static let shared = SunflowerPro()

    let store: LeeoStore

    /// 산 것 · 구독 중인 것 · 페이월 전에 설치한 사람.
    @Published private(set) var hasPro = false
    @Published private(set) var products: [Product] = []
    @Published private(set) var ownedProductIDs: Set<String> = []
    /// 지금 살아 있는 구독. 있으면 설정에 '평생으로 바꾸기' 가 선다.
    @Published private(set) var subscription: LeeoGraduation.Subscription?
    @Published private(set) var isWorking = false
    /// 사다가 막혔을 때 화면에 그대로 보여 줄 말.
    @Published private(set) var failureMessage: String?

    /// 지금 띄울 페이월. 앱 맨 위(ContentView)가 시트로 띄운다.
    @Published var moment: ProMoment?
    /// 구독 졸업 제안을 띄울 차례.
    @Published var showsGraduation = false

    /// **이 기기가 스토어에서 Pro 상품을 한 번이라도 불러왔는가.**
    ///
    /// 상품을 App Store Connect 에 만들기 전에 빌드가 나가면 아무도 살 수 없다. 그때 막으면
    /// 사지도 못하고 막히기만 한다. 그래서 한 번도 못 불러온 기기는 막지 않는다.
    /// 한 번 불러온 기기는 그 뒤 잠깐 네트워크가 끊겨도 다시 막는다(살 수 있는 상품이 있다는 걸 안다).
    @Published private(set) var sellsPro: Bool

    /// 페이월 전(1.1.0 빌드 9까지)에 설치한 사람. 한 번 true 면 바뀌지 않는다.
    @Published private(set) var installedBeforePaywall: Bool

    private let defaults = UserDefaults.standard
    private var observation: AnyCancellable?

    private static let sellsProKey = "pro.sellsPro"
    private static let legacyKey = "pro.installedBeforePaywall"
    private static func shownKey(_ moment: ProMoment) -> String { "pro.moment.shown." + moment.id }

    private init() {
        guard let config = SunlightTrackerSpec.paywall else {
            preconditionFailure("계약에 페이월이 없다. SunlightTrackerSpec.monetization 을 확인할 것")
        }
        sellsPro = defaults.bool(forKey: Self.sellsProKey)
        installedBeforePaywall = defaults.bool(forKey: Self.legacyKey)
        store = LeeoStore(config: config)
        // ⚠️ objectWillChange 는 값이 바뀌기 **직전**에 온다. 다음 차례로 미뤄서 읽는다.
        observation = store.objectWillChange.sink { [weak self] _ in
            Task { @MainActor in self?.pull() }
        }
        pull()
    }

    // MARK: 열려 있는가

    /// Pro 기능(위젯 · 실시간 현황 · 월간 통계)을 지금 써도 되는가.
    /// 아직 팔지 않는 기기에서는 막지 않는다.
    var isOpen: Bool { !sellsPro || hasPro }

    /// 평생 Pro(평생 · 구독 졸업)를 가졌는가.
    var ownsLifetime: Bool { !ownedProductIDs.isDisjoint(with: ProProduct.lifetimes) }

    func product(_ id: String) -> Product? { products.first { $0.id == id } }

    // MARK: 페이월 띄우기

    /// 막힌 자리에서 페이월을 띄운다.
    func present(_ moment: ProMoment) {
        guard self.moment == nil, !showsGraduation else { return }
        self.moment = moment
    }

    /// 저절로 뜨는 페이월(첫 세션 끝 · 일곱 번째 목표)은 순간마다 한 번만, 그리고 막혀 있을 때만.
    func offerOnce(_ moment: ProMoment) {
        guard !isOpen, self.moment == nil, !showsGraduation,
              !defaults.bool(forKey: Self.shownKey(moment)) else { return }
        defaults.set(true, forKey: Self.shownKey(moment))
        self.moment = moment
    }

    // MARK: 상태 맞추기

    /// 영수증을 다시 읽고 상품을 불러온다. 앱이 켜질 때와 다시 앞에 올 때마다 부른다.
    ///
    /// ⚠️ 순서가 중요하다. 페이월 전 설치자인지 **먼저** 알아본 뒤에 상품을 불러온다.
    ///    거꾸로 하면 상품이 보인 순간 잠깐 막혀서, 이미 올려 둔 위젯이 한 번 잠겼다 풀린다.
    func refresh() async {
        if !installedBeforePaywall, await Self.checkInstalledBeforePaywall() {
            installedBeforePaywall = true
            defaults.set(true, forKey: Self.legacyKey)
        }
        await store.refreshEntitlements()
        await store.loadProducts()
        subscription = await LeeoGraduation.currentSubscription(among: ProProduct.subscriptions)
        pull()
        if graduationIsDue, moment == nil { showsGraduation = true }
    }

    func loadProducts() async {
        await store.loadProducts()
        pull()
    }

    /// **구독 졸업을 제안할 때인가.** 6개월째와 갱신 7일 전에 한 번씩 (→ LeeoGraduation).
    /// 이미 평생을 가졌으면 제안하지 않는다. 띄운 쪽이 `markGraduationOffered()` 를 부른다.
    var graduationIsDue: Bool {
        guard let subscription, !ownsLifetime, product(ProProduct.graduate) != nil else { return false }
        return LeeoGraduation.isDue(subscription, lastOffered: LeeoGraduation.lastOffered())
    }

    func markGraduationOffered() { LeeoGraduation.markOffered() }

    // MARK: 사기 / 되찾기

    /// ⚠️ `action` 은 페이월의 `@Environment(\.purchase)` 다. 결제 시트가 이 창에 뜬다
    ///    (아이패드에서 엉뚱한 창에 뜨면 결제가 오류로 끝난다).
    func purchase(_ product: Product, using action: PurchaseAction) async {
        _ = await store.purchase(product) { try await action($0) }
        subscription = await LeeoGraduation.currentSubscription(among: ProProduct.subscriptions)
        pull()
    }

    /// 기기를 바꿨거나 앱을 지웠다 받은 사람이 되찾는 길. 심사에서도 요구한다.
    func restore() async {
        await store.restore()
        subscription = await LeeoGraduation.currentSubscription(among: ProProduct.subscriptions)
        pull()
        if !hasPro, failureMessage == nil {
            failureMessage = String(localized: "이 Apple 계정에서 구매한 기록을 찾지 못했어요.",
                                    comment: "Restore purchases: nothing found")
        }
    }

    /// 구독 졸업을 산 뒤 권한을 다시 읽는다.
    func refreshEntitlements() async {
        await store.refreshEntitlements()
        subscription = await LeeoGraduation.currentSubscription(among: ProProduct.subscriptions)
        pull()
    }

    // MARK: -

    private func pull() {
        hasPro = installedBeforePaywall || store.hasPro
        products = store.products
        ownedProductIDs = store.purchasedProductIDs
        isWorking = store.purchasingProductID != nil || store.isRestoring
        failureMessage = store.lastError
        // 팔 수 있는 Pro 상품이 하나라도 보였으면 그때부터 막는다.
        if !sellsPro, products.contains(where: { ProProduct.all.contains($0.id) }) {
            sellsPro = true
            defaults.set(true, forKey: Self.sellsProKey)
        }
        mirrorToWidgets()
    }

    /// 위젯은 앱 밖에서 돈다. 같은 답을 App Group 에 적고, 바뀌었을 때만 위젯을 다시 그린다.
    private func mirrorToWidgets() {
        guard SharedDataManager.shared.widgetsOpen != isOpen else { return }
        SharedDataManager.shared.widgetsOpen = isOpen
        WidgetCenter.shared.reloadAllTimelines()
    }

    // MARK: - 페이월 전에 설치한 사람

    /// 페이월이 없던 마지막 빌드(1.1.0 빌드 9). 이 빌드까지 받은 사람은 Pro 를 그대로 쓴다.
    /// 이미 홈 화면에 올려 둔 위젯이 업데이트 한 번에 잠기면 안 된다.
    nonisolated static let lastBuildBeforePaywall = 9

    /// App Store 가 서명한 최초 다운로드 빌드로 알아본다. 지웠다 다시 받아도 같다.
    /// 시험 환경(Xcode · 샌드박스)은 최초 빌드가 엉뚱하게 오므로 출시 영수증만 믿는다.
    private static func checkInstalledBeforePaywall() async -> Bool {
        guard case .verified(let app)? = try? await AppTransaction.shared,
              app.environment == .production else { return false }
        return isBuildBeforePaywall(app.originalAppVersion)
    }

    /// `originalAppVersion` 은 iOS 에서 CFBundleVersion(빌드 번호)이다.
    nonisolated static func isBuildBeforePaywall(_ originalAppVersion: String) -> Bool {
        guard let build = Int(originalAppVersion.split(separator: ".").first ?? "") else { return false }
        return build <= lastBuildBeforePaywall
    }
}

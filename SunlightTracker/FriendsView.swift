import SwiftUI

/// 친구 탭 - 함께 햇빛을 받은 친구들과의 관계도
struct FriendsView: View {
    @ObservedObject var manager: SunlightManager

    private var friends: [FriendRecord] {
        manager.nearbyManager.friends.sorted { $0.meetCount > $1.meetCount }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // 지금 함께하는 중 배지
                    if manager.nearbyManager.isSharedActivityActive {
                        activeNowCard
                    }

                    if friends.isEmpty {
                        emptyStateCard
                    } else {
                        // 관계도
                        relationshipCard

                        // 친구 목록
                        friendListCard
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("친구")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - 지금 함께하는 중
    private var activeNowCard: some View {
        HStack(spacing: 10) {
            Text("\u{1F31E}")
                .font(.title3)
            VStack(alignment: .leading, spacing: 2) {
                Text("지금 \(manager.nearbyManager.connectedPeerCount)명과 함께 햇빛 받는 중!")
                    .font(.subheadline.weight(.bold))
                    .foregroundColor(Color(red: 0.3, green: 0.65, blue: 0.2))
                if let distance = manager.nearbyManager.nearbyPeerDistance {
                    Text(String(format: "약 %.1fm 옆에 있어요", distance))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.green.opacity(0.1))
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.green.opacity(0.3), lineWidth: 1.5))
        )
    }

    // MARK: - 빈 상태
    private var emptyStateCard: some View {
        VStack(spacing: 12) {
            Text("\u{1F331}")
                .font(.system(size: 56))
            Text("아직 함께한 친구가 없어요")
                .font(.headline)
            Text("친구와 가까이에서 같이 햇빛을 받으면\n자동으로 여기에 기록돼요!")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
        .padding(.horizontal, 16)
        .background(RoundedRectangle(cornerRadius: 20).fill(Color(.secondarySystemGroupedBackground)))
    }

    // MARK: - 관계도
    private var relationshipCard: some View {
        VStack(spacing: 4) {
            HStack {
                Text("\u{1F33B} 함께한 친구들")
                    .font(.subheadline.weight(.bold))
                Spacer()
                Text("함께할수록 꽃이 커져요")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            FriendGraphView(friends: Array(friends.prefix(8)))
                .frame(height: 300)
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 20).fill(Color(.secondarySystemGroupedBackground)))
    }

    // MARK: - 친구 목록
    private var friendListCard: some View {
        VStack(spacing: 0) {
            ForEach(Array(friends.enumerated()), id: \.element.id) { index, friend in
                HStack(spacing: 12) {
                    Text(flowerEmoji(for: friend))
                        .font(.title3)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(friend.name)
                            .font(.subheadline.weight(.semibold))
                            .lineLimit(1)
                        Text("마지막 만남 \(friend.lastMet.friendDateString)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Text("\(friend.meetCount)번 함께")
                        .font(.system(.caption, design: .rounded).weight(.bold))
                        .foregroundColor(.orange)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Capsule().fill(Color.orange.opacity(0.12)))
                }
                .padding(.vertical, 12)

                if index < friends.count - 1 {
                    Divider()
                }
            }
        }
        .padding(.horizontal, 16)
        .background(RoundedRectangle(cornerRadius: 20).fill(Color(.secondarySystemGroupedBackground)))
    }

    private func flowerEmoji(for friend: FriendRecord) -> String {
        switch friend.meetCount {
        case ..<3: return "\u{1F33C}"      // 🌼
        case 3..<10: return "\u{1F337}"    // 🌷
        default: return "\u{1F33B}"        // 🌻
        }
    }
}

// MARK: - 관계도 그래프 (나를 중심으로 방사형 배치)
struct FriendGraphView: View {
    let friends: [FriendRecord]

    private var maxCount: Int {
        max(friends.map(\.meetCount).max() ?? 1, 1)
    }

    var body: some View {
        GeometryReader { geo in
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            let radius = min(geo.size.width, geo.size.height) / 2 - 46

            ZStack {
                // 연결선 (많이 만날수록 굵고 진하게)
                ForEach(Array(friends.enumerated()), id: \.element.id) { index, friend in
                    let pos = nodePosition(index: index, center: center, radius: radius)
                    Path { path in
                        path.move(to: center)
                        path.addLine(to: pos)
                    }
                    .stroke(
                        Color.orange.opacity(0.2 + 0.5 * strength(friend)),
                        style: StrokeStyle(lineWidth: 1.5 + 3 * strength(friend), lineCap: .round)
                    )
                }

                // 친구 노드
                ForEach(Array(friends.enumerated()), id: \.element.id) { index, friend in
                    let pos = nodePosition(index: index, center: center, radius: radius)
                    VStack(spacing: 2) {
                        Text(nodeEmoji(friend))
                            .font(.system(size: 24 + 14 * strength(friend)))
                        Text(friend.name)
                            .font(.caption2.weight(.semibold))
                            .lineLimit(1)
                            .frame(maxWidth: 76)
                        Text("\(friend.meetCount)번")
                            .font(.system(size: 9, design: .rounded))
                            .foregroundColor(.secondary)
                    }
                    .position(pos)
                }

                // 나 (중앙)
                VStack(spacing: 2) {
                    Text("\u{1F33B}")
                        .font(.system(size: 46))
                    Text("나")
                        .font(.caption.weight(.bold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color.orange.opacity(0.15)))
                }
                .position(center)
            }
        }
    }

    /// 만남 횟수 기반 강도 (0~1)
    private func strength(_ friend: FriendRecord) -> Double {
        Double(friend.meetCount) / Double(maxCount)
    }

    private func nodeEmoji(_ friend: FriendRecord) -> String {
        switch friend.meetCount {
        case ..<3: return "\u{1F33C}"
        case 3..<10: return "\u{1F337}"
        default: return "\u{1F33B}"
        }
    }

    /// 12시 방향부터 시계 방향 원형 배치
    private func nodePosition(index: Int, center: CGPoint, radius: CGFloat) -> CGPoint {
        let angle: Double = Double(index) / Double(max(friends.count, 1)) * 2 * .pi - .pi / 2
        return CGPoint(
            x: center.x + CGFloat(Foundation.cos(angle)) * radius,
            y: center.y + CGFloat(Foundation.sin(angle)) * radius
        )
    }
}

// MARK: - 날짜 표기
extension Date {
    var friendDateString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "M월 d일"
        return formatter.string(from: self)
    }
}

#Preview {
    FriendsView(manager: SunlightManager())
}

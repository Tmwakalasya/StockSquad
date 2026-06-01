import SwiftUI
import Charts

struct LeaderboardView: View {
    @EnvironmentObject var store: PortfolioStore

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bgGradient.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 18) {
                        ReturnsChartCard(members: store.leaderboard)
                        VStack(spacing: 12) {
                            ForEach(Array(store.leaderboard.enumerated()), id: \.element.id) { index, member in
                                LeaderboardRow(rank: index + 1, member: member)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 28)
                }
            }
            .navigationTitle("The Squad")
        }
    }
}

private struct ReturnsChartCard: View {
    let members: [Member]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Returns")
                .font(.headline)
                .foregroundStyle(Theme.textPrimary)
            Chart(members) { member in
                BarMark(
                    x: .value("Member", member.name),
                    y: .value("Return", member.totalGainPercent)
                )
                .foregroundStyle(Color.forChange(member.totalGain))
                .cornerRadius(6)
                .annotation(position: .top) {
                    Text(member.totalGainPercent.asSignedPercent)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(Theme.textSecondary)
                }
            }
            .chartXScale(domain: members.map(\.name))
            .chartYAxis {
                AxisMarks { _ in
                    AxisGridLine().foregroundStyle(Theme.stroke)
                    AxisValueLabel().foregroundStyle(Theme.textSecondary)
                }
            }
            .chartXAxis {
                AxisMarks { _ in
                    AxisValueLabel().foregroundStyle(Theme.textSecondary)
                }
            }
            .frame(height: 200)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle(padding: 18)
    }
}

private struct LeaderboardRow: View {
    let rank: Int
    let member: Member

    private var medal: String {
        switch rank {
        case 1: return "🥇"
        case 2: return "🥈"
        case 3: return "🥉"
        default: return "#\(rank)"
        }
    }
    private var isTop: Bool { rank == 1 }

    var body: some View {
        HStack(spacing: 14) {
            Text(medal)
                .font(.title3)
                .frame(width: 28)
            Text(member.avatar)
                .font(.system(size: 32))
                .frame(width: 52, height: 52)
                .background(Theme.bgRaised, in: Circle())
                .overlay(Circle().stroke(isTop ? Theme.gain : Theme.stroke, lineWidth: isTop ? 2 : 1))
            VStack(alignment: .leading, spacing: 3) {
                Text(member.name)
                    .font(.headline)
                    .foregroundStyle(Theme.textPrimary)
                Text(member.totalValue.asCurrency)
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 3) {
                Text(member.totalGainPercent.asSignedPercent)
                    .font(.headline)
                    .foregroundStyle(Color.forChange(member.totalGain))
                Text(member.totalGain.asCurrency)
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
            }
        }
        .padding(14)
        .background(isTop ? Theme.gain.opacity(0.10) : Theme.card,
                    in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(isTop ? Theme.gain.opacity(0.45) : Theme.stroke, lineWidth: 1)
        )
    }
}

import SwiftUI
import Charts

struct PortfolioView: View {
    @EnvironmentObject var store: PortfolioStore

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bgGradient.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 18) {
                        LiveStatusBar()
                        HeroCard(member: store.me)
                        AllocationCard(holdings: store.me.holdings, total: store.me.totalValue)
                        HoldingsCard(holdings: store.me.holdings)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 28)
                }
                .refreshable { await store.refreshQuotes() }
            }
            .navigationTitle("Portfolio")
            .task { await store.refreshQuotes() }
        }
    }
}

private struct HeroCard: View {
    let member: Member

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Total value")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white.opacity(0.85))
            Text(member.totalValue.asCurrency)
                .font(.system(size: 44, weight: .heavy, design: Theme.fontDesign))
                .foregroundStyle(.white)
            HStack(spacing: 6) {
                Image(systemName: member.totalGain >= 0 ? "arrow.up.right" : "arrow.down.right")
                    .font(.footnote.bold())
                Text(member.totalGain.asCurrency)
                Text("(\(member.totalGainPercent.asSignedPercent))")
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(.white.opacity(0.18), in: Capsule())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(24)
        .background(Theme.heroGradient, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
        .shadow(color: Theme.gain.opacity(0.22), radius: 18, y: 10)
    }
}

private struct AllocationCard: View {
    let holdings: [Holding]
    let total: Double

    private struct Slice: Identifiable {
        let id = UUID()
        let ticker: String
        let value: Double
        let percent: Double
        let color: Color
    }

    private var slices: [Slice] {
        holdings.enumerated().map { index, h in
            Slice(ticker: h.ticker,
                  value: h.marketValue,
                  percent: total == 0 ? 0 : h.marketValue / total * 100,
                  color: Theme.chartColors[index % Theme.chartColors.count])
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Allocation")
                .font(.headline)
                .foregroundStyle(Theme.textPrimary)

            ZStack {
                Chart(slices) { slice in
                    SectorMark(
                        angle: .value("Value", slice.value),
                        innerRadius: .ratio(0.64),
                        angularInset: 2
                    )
                    .cornerRadius(5)
                    .foregroundStyle(slice.color)
                }
                .frame(height: 190)

                VStack(spacing: 0) {
                    Text("\(holdings.count)")
                        .font(.system(size: 30, weight: .bold, design: Theme.fontDesign))
                        .foregroundStyle(Theme.textPrimary)
                    Text("holdings")
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)
                }
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())],
                      alignment: .leading, spacing: 10) {
                ForEach(slices) { slice in
                    HStack(spacing: 8) {
                        Circle().fill(slice.color).frame(width: 9, height: 9)
                        Text(slice.ticker)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Theme.textPrimary)
                        Spacer(minLength: 0)
                        Text(slice.percent.asPercent)
                            .font(.caption)
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle(padding: 18)
    }
}

private struct HoldingsCard: View {
    let holdings: [Holding]

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Your holdings")
                .font(.headline)
                .foregroundStyle(Theme.textPrimary)
                .padding(.bottom, 6)
            ForEach(Array(holdings.enumerated()), id: \.element.id) { index, holding in
                HoldingRow(holding: holding,
                           color: Theme.chartColors[index % Theme.chartColors.count])
                if index < holdings.count - 1 {
                    Divider().overlay(Theme.stroke)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle(padding: 18)
    }
}

private struct HoldingRow: View {
    let holding: Holding
    var color: Color = Theme.accent

    var body: some View {
        NavigationLink {
            StockDetailView(symbol: holding.ticker, name: holding.companyName, holding: holding)
        } label: {
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(color)
                    .frame(width: 4, height: 36)
                VStack(alignment: .leading, spacing: 3) {
                    Text(holding.ticker)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(Theme.textPrimary)
                    Text(holding.companyName)
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 3) {
                    Text(holding.marketValue.asCurrency)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.textPrimary)
                    Text(holding.gainPercent.asSignedPercent)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.forChange(holding.gain))
                }
                Image(systemName: "chevron.right")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(Theme.textSecondary)
            }
            .padding(.vertical, 9)
        }
        .buttonStyle(.plain)
    }
}

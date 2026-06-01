import SwiftUI

struct ScreenerView: View {
    @EnvironmentObject var store: PortfolioStore

    @State private var maxPrice: Double = 500
    @State private var minVolumeMillions: Double = 0
    @State private var pennyOnly = false
    @State private var watchlistOnly = false
    @State private var sort: SortOption = .topMovers

    enum SortOption: String, CaseIterable, Identifiable {
        case topMovers = "Top movers"
        case lowestPrice = "Lowest price"
        case mostLiquid = "Most liquid"
        var id: String { rawValue }
    }

    private var results: [ScreenerStock] {
        var list = store.screener.filter { stock in
            stock.price <= maxPrice &&
            stock.avgDailyVolume >= minVolumeMillions * 1_000_000 &&
            (!pennyOnly || stock.isPenny) &&
            (!watchlistOnly || store.isWatched(stock.ticker))
        }
        switch sort {
        case .topMovers:   list.sort { $0.dayChangePercent > $1.dayChangePercent }
        case .lowestPrice: list.sort { $0.price < $1.price }
        case .mostLiquid:  list.sort { $0.avgDailyVolume > $1.avgDailyVolume }
        }
        return list
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bgGradient.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 16) {
                        LiveStatusBar()
                        disclaimerCard
                        filtersCard
                        VStack(spacing: 10) {
                            HStack {
                                Text("\(results.count) matches")
                                    .font(.headline)
                                    .foregroundStyle(Theme.textPrimary)
                                Spacer()
                            }
                            ForEach(results) { stock in
                                ScreenerRow(stock: stock)
                            }
                            if results.isEmpty {
                                Text(watchlistOnly
                                     ? "No starred stocks yet. Tap the ☆ on any stock to add it here."
                                     : "No stocks match these filters. Try loosening them.")
                                    .font(.subheadline)
                                    .foregroundStyle(Theme.textSecondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.vertical, 8)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 28)
                }
                .refreshable { await store.refreshQuotes() }
            }
            .navigationTitle("Scout")
            .task { await store.refreshQuotes() }
        }
    }

    private var disclaimerCard: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
            Text("This screens stocks by the numbers you pick — it does **not** predict winners or give financial advice. Penny stocks are volatile and easy to manipulate; thin volume can mean you're stuck unable to sell. Always do your own research.")
                .font(.footnote)
                .foregroundStyle(Theme.textSecondary)
        }
        .padding(16)
        .background(Color.orange.opacity(0.10),
                    in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.orange.opacity(0.25), lineWidth: 1)
        )
    }

    private var filtersCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Max price: \(maxPrice.asCurrency)")
                    .font(.subheadline)
                    .foregroundStyle(Theme.textPrimary)
                Slider(value: $maxPrice, in: 1...500, step: 1)
                    .tint(Theme.gain)
            }
            VStack(alignment: .leading, spacing: 6) {
                Text("Min volume: \(minVolumeMillions.formatted(.number.precision(.fractionLength(0))))M shares/day")
                    .font(.subheadline)
                    .foregroundStyle(Theme.textPrimary)
                Slider(value: $minVolumeMillions, in: 0...50, step: 1)
                    .tint(Theme.gain)
            }
            Toggle("Penny stocks only (under $5)", isOn: $pennyOnly)
                .font(.subheadline)
                .foregroundStyle(Theme.textPrimary)
                .tint(Theme.gain)
            Toggle("Watchlist only ★", isOn: $watchlistOnly)
                .font(.subheadline)
                .foregroundStyle(Theme.textPrimary)
                .tint(Theme.gain)
            Picker("Sort by", selection: $sort) {
                ForEach(SortOption.allCases) { option in
                    Text(option.rawValue).tag(option)
                }
            }
            .pickerStyle(.segmented)
        }
        .cardStyle(padding: 18)
    }
}

private struct ScreenerRow: View {
    @EnvironmentObject var store: PortfolioStore
    let stock: ScreenerStock

    var body: some View {
        HStack(spacing: 12) {
            NavigationLink {
                StockDetailView(symbol: stock.ticker, name: stock.name)
            } label: {
                rowContent
            }
            .buttonStyle(.plain)

            Button {
                store.toggleWatchlist(stock.ticker)
            } label: {
                Image(systemName: store.isWatched(stock.ticker) ? "star.fill" : "star")
                    .font(.body)
                    .foregroundStyle(store.isWatched(stock.ticker) ? .yellow : Theme.textSecondary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(store.isWatched(stock.ticker) ? "Remove from watchlist" : "Add to watchlist")
        }
        .cardStyle(padding: 14)
    }

    private var rowContent: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Text(stock.ticker)
                        .font(.headline)
                        .foregroundStyle(Theme.textPrimary)
                    if stock.isPenny {
                        Text("PENNY")
                            .font(.caption2.bold())
                            .foregroundStyle(Color(red: 0.78, green: 0.62, blue: 1.0))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.purple.opacity(0.25), in: Capsule())
                    }
                }
                Text(stock.name)
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
                HStack(spacing: 6) {
                    Circle().fill(stock.risk.color).frame(width: 7, height: 7)
                    Text(stock.risk.rawValue)
                        .font(.caption2)
                        .foregroundStyle(Theme.textSecondary)
                    Text("· Vol \(stock.avgDailyVolume.asCompactNumber)")
                        .font(.caption2)
                        .foregroundStyle(Theme.textSecondary)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 6) {
                Text(stock.price.asCurrency)
                    .font(.headline)
                    .foregroundStyle(Theme.textPrimary)
                Text(stock.dayChangePercent.asSignedPercent)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.forChange(stock.dayChangePercent))
                    .padding(.horizontal, 7)
                    .padding(.vertical, 2)
                    .background(Color.forChange(stock.dayChangePercent).opacity(0.15), in: Capsule())
                Text(stock.marketCap.asCompactCurrency)
                    .font(.caption2)
                    .foregroundStyle(Theme.textSecondary)
            }
        }
    }
}

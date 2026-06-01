import SwiftUI
import Charts

// The screen you land on after tapping a stock — anywhere in the app.
//
// Shows a price chart with a 1D/1W/1M/3M/1Y range selector, the live price and
// move over that range, and a few key stats. Open it from a holding and it also
// shows your position's profit/loss. The star in the top-right adds the stock to
// your watchlist.

struct StockDetailView: View {
    let symbol: String
    let name: String
    /// Set when opened from something you own, so we can show your P&L.
    var holding: Holding? = nil

    @EnvironmentObject var store: PortfolioStore

    @State private var range: ChartRange = .month
    @State private var series: PriceSeries?
    @State private var isLoading = false
    @State private var loadFailed = false

    var body: some View {
        ZStack {
            Theme.bgGradient.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 16) {
                    header
                    chartCard
                    rangePicker
                    if let holding { positionCard(holding) }
                    statsCard
                    disclaimer
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 28)
            }
        }
        .navigationTitle(symbol)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    store.toggleWatchlist(symbol)
                } label: {
                    Image(systemName: store.isWatched(symbol) ? "star.fill" : "star")
                        .foregroundStyle(store.isWatched(symbol) ? .yellow : Theme.textSecondary)
                }
                .accessibilityLabel(store.isWatched(symbol) ? "Remove from watchlist" : "Add to watchlist")
            }
        }
        .task(id: range) { await load() }
    }

    // MARK: - Loading

    private func load() async {
        isLoading = true
        loadFailed = false
        do {
            series = try await ChartDataService.series(for: symbol, range: range)
        } catch {
            loadFailed = true
        }
        isLoading = false
    }

    // MARK: - Header (name, big price, range move)

    private var currentPrice: Double {
        series?.currentPrice ?? holding?.currentPrice ?? 0
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(name)
                .font(.subheadline)
                .foregroundStyle(Theme.textSecondary)
            Text(currentPrice.asCurrency)
                .font(.system(size: 40, weight: .heavy, design: Theme.fontDesign))
                .foregroundStyle(Theme.textPrimary)
            if let series, !series.points.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: series.rangeChange >= 0 ? "arrow.up.right" : "arrow.down.right")
                    Text(series.rangeChange.asCurrency)
                    Text("(\(series.rangeChangePercent.asSignedPercent))")
                    Text(range.rawValue)
                        .foregroundStyle(Theme.textSecondary)
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.forChange(series.rangeChange))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Chart

    private var lineColor: Color {
        guard let series else { return Theme.accent }
        return series.rangeChange >= 0 ? Theme.gain : Theme.loss
    }

    private var yDomain: ClosedRange<Double> {
        guard let series, !series.points.isEmpty else { return 0...1 }
        let low = series.low
        let high = series.high
        // Keep a non-zero band even if the price barely moved, so the line
        // doesn't hug the top or bottom edge.
        let pad = max((high - low) * 0.08, high * 0.01, 0.5)
        return (low - pad)...(high + pad)
    }

    private var chartCard: some View {
        Group {
            if let series, !series.points.isEmpty {
                Chart(series.points) { point in
                    LineMark(
                        x: .value("Time", point.date),
                        y: .value("Price", point.close)
                    )
                    .foregroundStyle(lineColor)
                    .interpolationMethod(.catmullRom)

                    AreaMark(
                        x: .value("Time", point.date),
                        y: .value("Price", point.close)
                    )
                    .foregroundStyle(.linearGradient(
                        colors: [lineColor.opacity(0.25), lineColor.opacity(0.0)],
                        startPoint: .top, endPoint: .bottom))
                    .interpolationMethod(.catmullRom)
                }
                .chartYScale(domain: yDomain)
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                        AxisGridLine().foregroundStyle(Theme.stroke.opacity(0.5))
                        AxisValueLabel().foregroundStyle(Theme.textSecondary)
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .trailing) { _ in
                        AxisGridLine().foregroundStyle(Theme.stroke.opacity(0.4))
                        AxisValueLabel().foregroundStyle(Theme.textSecondary)
                    }
                }
                .frame(height: 220)
            } else if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .frame(height: 220)
            } else if loadFailed {
                VStack(spacing: 10) {
                    Image(systemName: "wifi.slash")
                        .font(.title2)
                        .foregroundStyle(Theme.textSecondary)
                    Text("Couldn't load the chart")
                        .font(.subheadline)
                        .foregroundStyle(Theme.textSecondary)
                    Button("Try again") { Task { await load() } }
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.accent)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 220)
            } else {
                Text("No chart data")
                    .font(.subheadline)
                    .foregroundStyle(Theme.textSecondary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 220)
            }
        }
        .cardStyle(padding: 16)
    }

    private var rangePicker: some View {
        Picker("Range", selection: $range) {
            ForEach(ChartRange.allCases) { option in
                Text(option.rawValue).tag(option)
            }
        }
        .pickerStyle(.segmented)
    }

    // MARK: - Your position (only when opened from a holding)

    private func positionCard(_ holding: Holding) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Your position")
                .font(.headline)
                .foregroundStyle(Theme.textPrimary)
                .padding(.bottom, 4)
            statRow("Shares", holding.shares.formatted(.number.precision(.fractionLength(0...2))))
            Divider().overlay(Theme.stroke)
            statRow("Avg cost", holding.avgCost.asCurrency)
            Divider().overlay(Theme.stroke)
            statRow("Market value", holding.marketValue.asCurrency)
            Divider().overlay(Theme.stroke)
            statRow("Total return",
                    "\(holding.gain.asCurrency)  (\(holding.gainPercent.asSignedPercent))",
                    color: Color.forChange(holding.gain))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle(padding: 16)
    }

    // MARK: - Key stats (derived from the chart series)

    private var statsCard: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Stats")
                .font(.headline)
                .foregroundStyle(Theme.textPrimary)
                .padding(.bottom, 4)
            statRow("Previous close", series.map { $0.previousClose.asCurrency } ?? "—")
            Divider().overlay(Theme.stroke)
            statRow("\(range.rawValue) high", series.map { $0.high.asCurrency } ?? "—")
            Divider().overlay(Theme.stroke)
            statRow("\(range.rawValue) low", series.map { $0.low.asCurrency } ?? "—")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle(padding: 16)
    }

    private func statRow(_ label: String, _ value: String, color: Color = Theme.textPrimary) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(Theme.textSecondary)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(color)
        }
        .padding(.vertical, 9)
    }

    // MARK: - Disclaimer

    private var disclaimer: some View {
        Text("Prices are delayed and for information only — this isn't financial advice. Do your own research before trading.")
            .font(.caption2)
            .foregroundStyle(Theme.textSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 4)
    }
}

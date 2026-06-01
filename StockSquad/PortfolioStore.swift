import SwiftUI
import Combine

// The app's single source of truth. Seeded with sample data, then updated
// in place with live prices from QuoteService (Phase 2).
//
// Phase 3 (shared backend): replace the sample seeds with calls to your
// backend (e.g. Supabase). The views won't change — they only read this store.

@MainActor
final class PortfolioStore: ObservableObject {
    @Published var members: [Member] = SampleData.members
    @Published var screener: [ScreenerStock] = SampleData.screener

    @Published var lastUpdated: Date?
    @Published var isRefreshing = false

    /// Tickers the user has starred to follow without owning. Persists locally
    /// (Phase 3 moves this to the shared backend so it syncs across the squad).
    @Published var watchlist: Set<String> = PortfolioStore.loadWatchlist()

    /// "You" — the first member. Phase 3 ties this to the logged-in user.
    var me: Member { members[0] }

    /// The squad ranked by percentage return, best first.
    var leaderboard: [Member] {
        members.sorted { $0.totalGainPercent > $1.totalGainPercent }
    }

    /// True when no Finnhub key is set — the UI shows a hint and stays on sample data.
    var needsAPIKey: Bool { !QuoteService.isConfigured }

    /// Pull live prices for every ticker we display, then update holdings and
    /// the screener in place. Safe to call repeatedly; no-ops without a key.
    func refreshQuotes() async {
        guard QuoteService.isConfigured, !isRefreshing else { return }
        isRefreshing = true
        defer { isRefreshing = false }

        let quotes = await QuoteService.quotes(for: allSymbols())
        guard !quotes.isEmpty else { return }

        members = members.map { member in
            var member = member
            member.holdings = member.holdings.map { holding in
                var holding = holding
                if let q = quotes[holding.ticker] { holding.currentPrice = q.price }
                return holding
            }
            return member
        }

        screener = screener.map { stock in
            var stock = stock
            if let q = quotes[stock.ticker] {
                stock.price = q.price
                stock.dayChangePercent = q.dayChangePercent
            }
            return stock
        }

        lastUpdated = Date()
    }

    // MARK: - Watchlist

    func isWatched(_ symbol: String) -> Bool { watchlist.contains(symbol) }

    /// Star or unstar a ticker, then save so it survives an app relaunch.
    func toggleWatchlist(_ symbol: String) {
        if watchlist.contains(symbol) {
            watchlist.remove(symbol)
        } else {
            watchlist.insert(symbol)
        }
        Self.saveWatchlist(watchlist)
    }

    private static let watchlistKey = "watchlist"

    private static func loadWatchlist() -> Set<String> {
        Set(UserDefaults.standard.stringArray(forKey: watchlistKey) ?? [])
    }

    private static func saveWatchlist(_ symbols: Set<String>) {
        UserDefaults.standard.set(Array(symbols), forKey: watchlistKey)
    }

    /// Every unique ticker across all holdings and the screener.
    private func allSymbols() -> [String] {
        var symbols = Set<String>()
        for member in members {
            for holding in member.holdings { symbols.insert(holding.ticker) }
        }
        for stock in screener { symbols.insert(stock.ticker) }
        return Array(symbols)
    }
}

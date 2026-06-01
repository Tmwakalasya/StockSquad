import Foundation

// Fetches a stock's price history for the detail screen's chart.
//
// Source: Yahoo Finance's public chart endpoint. No API key needed (it just
// wants a browser-like User-Agent), and it returns both intraday and daily
// history — that's what powers the 1D / 1W / 1M / 3M / 1Y range buttons.
//
// Like QuoteService, this only reads public market prices. It never touches a
// brokerage account.

// MARK: - What the view gets back

struct PricePoint: Identifiable {
    let id = UUID()
    let date: Date
    let close: Double
}

struct PriceSeries {
    let points: [PricePoint]
    let currentPrice: Double   // latest price from the feed
    let previousClose: Double  // the close before this range started

    var first: Double { points.first?.close ?? currentPrice }
    var last: Double { points.last?.close ?? currentPrice }
    var rangeChange: Double { last - first }
    var rangeChangePercent: Double { first == 0 ? 0 : rangeChange / first * 100 }
    var high: Double { points.map(\.close).max() ?? currentPrice }
    var low: Double { points.map(\.close).min() ?? currentPrice }
}

// MARK: - The selectable time ranges

enum ChartRange: String, CaseIterable, Identifiable {
    case day = "1D"
    case week = "1W"
    case month = "1M"
    case threeMonths = "3M"
    case year = "1Y"

    var id: String { rawValue }

    /// Yahoo's "range" query value.
    var apiRange: String {
        switch self {
        case .day:          return "1d"
        case .week:         return "5d"
        case .month:        return "1mo"
        case .threeMonths:  return "3mo"
        case .year:         return "1y"
        }
    }

    /// How fine-grained each point is — intraday for short ranges, daily/weekly for long ones.
    var apiInterval: String {
        switch self {
        case .day:          return "5m"
        case .week:         return "30m"
        case .month:        return "1d"
        case .threeMonths:  return "1d"
        case .year:         return "1wk"
        }
    }
}

// MARK: - The fetcher

enum ChartDataService {
    static func series(for symbol: String, range: ChartRange) async throws -> PriceSeries {
        var comps = URLComponents(string: "https://query1.finance.yahoo.com/v8/finance/chart/\(symbol)")!
        comps.queryItems = [
            URLQueryItem(name: "range", value: range.apiRange),
            URLQueryItem(name: "interval", value: range.apiInterval)
        ]

        var request = URLRequest(url: comps.url!)
        // Yahoo blocks requests without a browser-like agent.
        request.setValue("Mozilla/5.0", forHTTPHeaderField: "User-Agent")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        let decoded = try JSONDecoder().decode(YahooChart.self, from: data)
        guard let result = decoded.chart.result?.first else {
            throw URLError(.cannotParseResponse)
        }

        let timestamps = result.timestamp ?? []
        let closes = result.indicators?.quote.first?.close ?? []

        // Pair each timestamp with its close, skipping any gaps (Yahoo sends
        // nulls for minutes with no trade).
        var points: [PricePoint] = []
        for (index, stamp) in timestamps.enumerated() where index < closes.count {
            if let close = closes[index] {
                points.append(PricePoint(date: Date(timeIntervalSince1970: TimeInterval(stamp)),
                                         close: close))
            }
        }

        let meta = result.meta
        return PriceSeries(
            points: points,
            currentPrice: meta?.regularMarketPrice ?? points.last?.close ?? 0,
            previousClose: meta?.chartPreviousClose ?? meta?.previousClose ?? points.first?.close ?? 0
        )
    }
}

// MARK: - JSON shapes (only the fields we use)

private struct YahooChart: Decodable {
    let chart: Chart

    struct Chart: Decodable {
        let result: [Result]?
    }
    struct Result: Decodable {
        let meta: Meta?
        let timestamp: [Int]?
        let indicators: Indicators?
    }
    struct Meta: Decodable {
        let regularMarketPrice: Double?
        let chartPreviousClose: Double?
        let previousClose: Double?
    }
    struct Indicators: Decodable {
        let quote: [Quote]
    }
    struct Quote: Decodable {
        let close: [Double?]?
    }
}

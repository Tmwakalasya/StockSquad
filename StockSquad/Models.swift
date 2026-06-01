import SwiftUI

// MARK: - Holding (one position a person owns)

struct Holding: Identifiable {
    let id = UUID()
    let ticker: String
    let companyName: String
    var shares: Double
    var avgCost: Double       // average price paid per share
    var currentPrice: Double  // latest market price (Stage 2 makes this live)

    var marketValue: Double { shares * currentPrice }
    var costBasis: Double { shares * avgCost }
    var gain: Double { marketValue - costBasis }
    var gainPercent: Double {
        costBasis == 0 ? 0 : (gain / costBasis) * 100
    }
}

// MARK: - Member (you or a friend in the squad)

struct Member: Identifiable {
    let id = UUID()
    let name: String
    let avatar: String        // an emoji, just for fun
    var holdings: [Holding]

    var totalValue: Double { holdings.reduce(0) { $0 + $1.marketValue } }
    var totalCost: Double { holdings.reduce(0) { $0 + $1.costBasis } }
    var totalGain: Double { totalValue - totalCost }
    var totalGainPercent: Double {
        totalCost == 0 ? 0 : (totalGain / totalCost) * 100
    }
}

// MARK: - ScreenerStock (a stock the "Scout" tab can surface)

struct ScreenerStock: Identifiable {
    let id = UUID()
    let ticker: String
    let name: String
    var price: Double
    var dayChangePercent: Double
    let marketCap: Double
    let avgDailyVolume: Double   // shares traded per day — a liquidity gauge
    let sector: String

    /// Common rule of thumb: a "penny stock" trades under $5.
    var isPenny: Bool { price < 5 }

    /// A transparent, rules-based risk read — NOT a prediction or advice.
    /// Penny price = riskier; thin volume = riskier (you may not be able to sell).
    var risk: RiskLevel {
        let thinVolume = avgDailyVolume < 500_000
        switch (isPenny, thinVolume) {
        case (true, true):   return .high
        case (true, false):  return .medium
        case (false, true):  return .medium
        case (false, false): return .low
        }
    }
}

enum RiskLevel: String {
    case low = "Lower risk"
    case medium = "Medium risk"
    case high = "High risk"

    var color: Color {
        switch self {
        case .low: return .green
        case .medium: return .orange
        case .high: return .red
        }
    }
}

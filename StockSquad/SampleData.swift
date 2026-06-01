import Foundation

// Fake-but-realistic data so the app is fully clickable before any live data
// or accounts exist. Stage 2+ replaces these with real sources.

enum SampleData {
    static let members: [Member] = [
        Member(name: "Wes", avatar: "🦅", holdings: [
            Holding(ticker: "AAPL", companyName: "Apple",   shares: 8,   avgCost: 165.20, currentPrice: 198.40),
            Holding(ticker: "NVDA", companyName: "NVIDIA",  shares: 5,   avgCost: 88.10,  currentPrice: 121.30),
            Holding(ticker: "SOFI", companyName: "SoFi",    shares: 120, avgCost: 7.40,   currentPrice: 9.85),
            Holding(ticker: "F",    companyName: "Ford",    shares: 60,  avgCost: 12.10,  currentPrice: 11.05),
        ]),
        Member(name: "Nuno", avatar: "🐺", holdings: [
            Holding(ticker: "TSLA", companyName: "Tesla",    shares: 6,  avgCost: 210.00, currentPrice: 248.50),
            Holding(ticker: "PLTR", companyName: "Palantir", shares: 90, avgCost: 18.30,  currentPrice: 24.10),
            Holding(ticker: "AMD",  companyName: "AMD",      shares: 10, avgCost: 142.00, currentPrice: 128.70),
        ]),
        Member(name: "Ethan", avatar: "🦊", holdings: [
            Holding(ticker: "MSFT", companyName: "Microsoft", shares: 4,  avgCost: 330.00, currentPrice: 421.90),
            Holding(ticker: "VTI",  companyName: "Vanguard Total Mkt", shares: 15, avgCost: 220.00, currentPrice: 268.40),
            Holding(ticker: "NIO",  companyName: "NIO",       shares: 200, avgCost: 6.10,  currentPrice: 4.75),
        ]),
        Member(name: "Tuntu", avatar: "🐢", holdings: [
            Holding(ticker: "SPY",  companyName: "S&P 500 ETF", shares: 9, avgCost: 430.00, currentPrice: 521.10),
            Holding(ticker: "COIN", companyName: "Coinbase",    shares: 7, avgCost: 165.00, currentPrice: 205.30),
        ]),
    ]

    static let screener: [ScreenerStock] = [
        // Large caps
        ScreenerStock(ticker: "AAPL", name: "Apple",         price: 198.40, dayChangePercent:  0.8, marketCap: 3_050_000_000_000, avgDailyVolume: 54_000_000,  sector: "Technology"),
        ScreenerStock(ticker: "NVDA", name: "NVIDIA",        price: 121.30, dayChangePercent:  2.4, marketCap: 2_980_000_000_000, avgDailyVolume: 310_000_000, sector: "Technology"),
        ScreenerStock(ticker: "AMD",  name: "AMD",           price: 128.70, dayChangePercent: -1.1, marketCap: 208_000_000_000,   avgDailyVolume: 48_000_000,  sector: "Technology"),
        ScreenerStock(ticker: "F",    name: "Ford",          price: 11.05,  dayChangePercent:  0.3, marketCap: 44_000_000_000,    avgDailyVolume: 62_000_000,  sector: "Auto"),
        // Mid / small caps
        ScreenerStock(ticker: "SOFI", name: "SoFi",          price: 9.85,   dayChangePercent:  3.1, marketCap: 10_500_000_000,    avgDailyVolume: 51_000_000,  sector: "Financials"),
        ScreenerStock(ticker: "PLTR", name: "Palantir",      price: 24.10,  dayChangePercent:  1.7, marketCap: 53_000_000_000,    avgDailyVolume: 40_000_000,  sector: "Technology"),
        // Penny stocks — varied liquidity on purpose
        ScreenerStock(ticker: "NIO",  name: "NIO",           price: 4.75,   dayChangePercent: -2.2, marketCap: 9_800_000_000,     avgDailyVolume: 38_000_000,  sector: "Auto"),
        ScreenerStock(ticker: "PLUG", name: "Plug Power",    price: 2.34,   dayChangePercent:  5.6, marketCap: 2_100_000_000,     avgDailyVolume: 22_000_000,  sector: "Energy"),
        ScreenerStock(ticker: "SNDL", name: "SNDL Inc.",     price: 1.78,   dayChangePercent: -3.4, marketCap: 460_000_000,       avgDailyVolume: 8_000_000,   sector: "Cannabis"),
        ScreenerStock(ticker: "GEVO", name: "Gevo",          price: 1.42,   dayChangePercent:  7.9, marketCap: 340_000_000,       avgDailyVolume: 3_400_000,   sector: "Energy"),
        ScreenerStock(ticker: "BBAI", name: "BigBear.ai",    price: 2.05,   dayChangePercent:  9.2, marketCap: 520_000_000,       avgDailyVolume: 6_700_000,   sector: "Technology"),
        ScreenerStock(ticker: "CIFR", name: "Cipher Mining", price: 4.10,   dayChangePercent:  4.4, marketCap: 1_400_000_000,     avgDailyVolume: 12_000_000,  sector: "Crypto"),
        // Thin, very speculative penny names (flag as high risk via low volume)
        ScreenerStock(ticker: "MULN", name: "Mullen Auto.",  price: 0.42,   dayChangePercent: 12.5, marketCap: 22_000_000,        avgDailyVolume: 410_000,     sector: "Auto"),
        ScreenerStock(ticker: "GNS",  name: "Genius Group",  price: 0.88,   dayChangePercent: -8.7, marketCap: 31_000_000,        avgDailyVolume: 250_000,     sector: "Education"),
        ScreenerStock(ticker: "XELA", name: "Exela Tech.",   price: 0.31,   dayChangePercent: 18.0, marketCap: 18_000_000,        avgDailyVolume: 180_000,     sector: "Technology"),
    ]
}

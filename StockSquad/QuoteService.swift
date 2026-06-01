import Foundation

// Phase 2: live quotes from Finnhub (https://finnhub.io).
//
// The key (in git-ignored Secrets.swift) only reads PUBLIC prices — it can't
// see or touch anyone's brokerage account. In Phase 3 the backend holds it
// instead, so the app ships without any key inside it.

struct Quote {
    let price: Double
    let dayChangePercent: Double
}

enum QuoteService {
    /// False until a real key is pasted into Secrets.swift.
    static var isConfigured: Bool {
        !Secrets.finnhubKey.isEmpty &&
        Secrets.finnhubKey != "PASTE_YOUR_FINNHUB_KEY_HERE"
    }

    /// One symbol's quote. Throws on network / bad-status / decode failure.
    static func quote(for symbol: String) async throws -> Quote {
        var comps = URLComponents(string: "https://finnhub.io/api/v1/quote")!
        comps.queryItems = [
            URLQueryItem(name: "symbol", value: symbol),
            URLQueryItem(name: "token", value: Secrets.finnhubKey),
        ]
        let (data, response) = try await URLSession.shared.data(from: comps.url!)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        let raw = try JSONDecoder().decode(FinnhubQuote.self, from: data)
        return Quote(price: raw.c, dayChangePercent: raw.dp ?? 0)
    }

    /// Many symbols at once (fetched concurrently). Symbols that fail or return
    /// no price are simply left out of the result.
    static func quotes(for symbols: [String]) async -> [String: Quote] {
        await withTaskGroup(of: (String, Quote?).self) { group in
            for symbol in symbols {
                group.addTask { (symbol, try? await quote(for: symbol)) }
            }
            var result: [String: Quote] = [:]
            for await (symbol, quote) in group {
                if let quote, quote.price > 0 { result[symbol] = quote }
            }
            return result
        }
    }
}

// Finnhub's /quote response. We only need current price (c) and percent
// change (dp); dp can be null before the market opens, so it's optional.
private struct FinnhubQuote: Decodable {
    let c: Double
    let dp: Double?
}

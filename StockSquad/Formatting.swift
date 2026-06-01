import SwiftUI

// Small number-formatting helpers used across the app.

extension Double {
    /// "$1,234.56"
    var asCurrency: String {
        formatted(.currency(code: "USD"))
    }

    /// Always shows a sign, e.g. "+12.4%" or "-3.1%".
    /// Input is a percent value like 12.4 (not 0.124).
    var asSignedPercent: String {
        let prefix = self >= 0 ? "+" : ""
        return prefix + (self / 100).formatted(.percent.precision(.fractionLength(1)))
    }

    /// Unsigned percent, e.g. "24.3%". Input is a percent value like 24.3.
    var asPercent: String {
        (self / 100).formatted(.percent.precision(.fractionLength(1)))
    }

    /// Big money, compact: 3_050_000_000_000 -> "$3.05T".
    var asCompactCurrency: String { "$" + scaled() }

    /// Big counts, compact: 54_000_000 -> "54M".
    var asCompactNumber: String { scaled() }

    private func scaled() -> String {
        let n = abs(self)
        func f(_ v: Double, _ suffix: String) -> String {
            v.formatted(.number.precision(.fractionLength(0...2))) + suffix
        }
        switch n {
        case 1_000_000_000_000...: return f(self / 1_000_000_000_000, "T")
        case 1_000_000_000...:     return f(self / 1_000_000_000, "B")
        case 1_000_000...:         return f(self / 1_000_000, "M")
        case 1_000...:             return f(self / 1_000, "K")
        default:                   return formatted(.number.precision(.fractionLength(0...2)))
        }
    }
}

extension Color {
    /// Green for gains, red for losses.
    static func forChange(_ value: Double) -> Color {
        value >= 0 ? Theme.gain : Theme.loss
    }
}

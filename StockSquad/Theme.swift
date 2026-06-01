import SwiftUI
import Combine

// MARK: - Palette

/// A complete look: surface colors, text, accents, a chart palette,
/// plus the font design and light/dark mode that go with it.
struct Palette {
    let bg: Color
    let bgRaised: Color
    let card: Color
    let stroke: Color

    let textPrimary: Color
    let textSecondary: Color

    let gain: Color
    let loss: Color
    let accent: Color

    let heroA: Color   // hero gradient start
    let heroB: Color   // hero gradient end

    let chartColors: [Color]

    let fontDesign: Font.Design
    let colorScheme: ColorScheme
}

// MARK: - The themes

enum ThemeChoice: String, CaseIterable, Identifiable {
    case midnight, daylight, synthwave, terminal, sunset, ocean

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .midnight:  return "Midnight"
        case .daylight:  return "Daylight"
        case .synthwave: return "Synthwave"
        case .terminal:  return "Terminal"
        case .sunset:    return "Sunset"
        case .ocean:     return "Ocean"
        }
    }

    /// Short label describing the typeface, shown on the Style screen.
    var fontLabel: String {
        switch palette.fontDesign {
        case .rounded:    return "Rounded"
        case .serif:      return "Serif"
        case .monospaced: return "Mono"
        default:          return "System"
        }
    }

    var palette: Palette {
        switch self {
        case .midnight:  return .midnight
        case .daylight:  return .daylight
        case .synthwave: return .synthwave
        case .terminal:  return .terminal
        case .sunset:    return .sunset
        case .ocean:     return .ocean
        }
    }
}

extension Palette {
    static let midnight = Palette(
        bg:       Color(red: 0.05, green: 0.06, blue: 0.09),
        bgRaised: Color(red: 0.09, green: 0.10, blue: 0.14),
        card:     Color(red: 0.11, green: 0.12, blue: 0.16),
        stroke:   Color.white.opacity(0.07),
        textPrimary:   Color(red: 0.96, green: 0.97, blue: 0.99),
        textSecondary: Color(red: 0.56, green: 0.59, blue: 0.66),
        gain:   Color(red: 0.20, green: 0.90, blue: 0.55),
        loss:   Color(red: 1.00, green: 0.38, blue: 0.40),
        accent: Color(red: 0.20, green: 0.90, blue: 0.55),
        heroA:  Color(red: 0.11, green: 0.55, blue: 0.42),
        heroB:  Color(red: 0.06, green: 0.30, blue: 0.52),
        chartColors: [
            Color(red: 0.20, green: 0.90, blue: 0.55),
            Color(red: 0.30, green: 0.66, blue: 1.00),
            Color(red: 0.78, green: 0.52, blue: 1.00),
            Color(red: 1.00, green: 0.72, blue: 0.32),
            Color(red: 1.00, green: 0.46, blue: 0.62),
            Color(red: 0.40, green: 0.86, blue: 0.86),
            Color(red: 0.96, green: 0.86, blue: 0.42),
        ],
        fontDesign: .rounded,
        colorScheme: .dark
    )

    static let daylight = Palette(
        bg:       Color(red: 0.95, green: 0.96, blue: 0.98),
        bgRaised: Color(red: 0.99, green: 0.99, blue: 1.00),
        card:     Color.white,
        stroke:   Color.black.opacity(0.08),
        textPrimary:   Color(red: 0.10, green: 0.12, blue: 0.16),
        textSecondary: Color(red: 0.40, green: 0.44, blue: 0.50),
        gain:   Color(red: 0.13, green: 0.66, blue: 0.40),
        loss:   Color(red: 0.86, green: 0.25, blue: 0.30),
        accent: Color(red: 0.13, green: 0.66, blue: 0.40),
        heroA:  Color(red: 0.16, green: 0.62, blue: 0.46),
        heroB:  Color(red: 0.10, green: 0.40, blue: 0.62),
        chartColors: [
            Color(red: 0.13, green: 0.66, blue: 0.42),
            Color(red: 0.20, green: 0.50, blue: 0.90),
            Color(red: 0.55, green: 0.40, blue: 0.85),
            Color(red: 0.95, green: 0.60, blue: 0.20),
            Color(red: 0.90, green: 0.35, blue: 0.55),
            Color(red: 0.15, green: 0.65, blue: 0.65),
            Color(red: 0.45, green: 0.45, blue: 0.85),
        ],
        fontDesign: .default,
        colorScheme: .light
    )

    static let synthwave = Palette(
        bg:       Color(red: 0.07, green: 0.05, blue: 0.13),
        bgRaised: Color(red: 0.11, green: 0.08, blue: 0.20),
        card:     Color(red: 0.15, green: 0.10, blue: 0.27),
        stroke:   Color.white.opacity(0.10),
        textPrimary:   Color(red: 0.98, green: 0.96, blue: 1.00),
        textSecondary: Color(red: 0.70, green: 0.62, blue: 0.85),
        gain:   Color(red: 0.30, green: 0.98, blue: 0.78),
        loss:   Color(red: 1.00, green: 0.33, blue: 0.66),
        accent: Color(red: 0.92, green: 0.36, blue: 0.85),
        heroA:  Color(red: 0.55, green: 0.18, blue: 0.78),
        heroB:  Color(red: 0.16, green: 0.20, blue: 0.75),
        chartColors: [
            Color(red: 0.92, green: 0.36, blue: 0.85),
            Color(red: 0.30, green: 0.90, blue: 0.95),
            Color(red: 0.65, green: 0.40, blue: 1.00),
            Color(red: 1.00, green: 0.40, blue: 0.70),
            Color(red: 0.40, green: 0.55, blue: 1.00),
            Color(red: 0.40, green: 0.98, blue: 0.80),
            Color(red: 0.98, green: 0.85, blue: 0.40),
        ],
        fontDesign: .rounded,
        colorScheme: .dark
    )

    static let terminal = Palette(
        bg:       Color(red: 0.02, green: 0.03, blue: 0.02),
        bgRaised: Color(red: 0.04, green: 0.06, blue: 0.04),
        card:     Color(red: 0.05, green: 0.09, blue: 0.06),
        stroke:   Color(red: 0.30, green: 0.95, blue: 0.40).opacity(0.16),
        textPrimary:   Color(red: 0.80, green: 0.98, blue: 0.80),
        textSecondary: Color(red: 0.40, green: 0.70, blue: 0.45),
        gain:   Color(red: 0.30, green: 0.95, blue: 0.40),
        loss:   Color(red: 1.00, green: 0.45, blue: 0.40),
        accent: Color(red: 0.30, green: 0.95, blue: 0.40),
        heroA:  Color(red: 0.02, green: 0.22, blue: 0.07),
        heroB:  Color(red: 0.02, green: 0.10, blue: 0.04),
        chartColors: [
            Color(red: 0.30, green: 0.95, blue: 0.40),
            Color(red: 0.20, green: 0.80, blue: 0.60),
            Color(red: 0.60, green: 0.95, blue: 0.30),
            Color(red: 0.95, green: 0.80, blue: 0.30),
            Color(red: 0.30, green: 0.85, blue: 0.85),
            Color(red: 0.50, green: 0.90, blue: 0.50),
            Color(red: 0.80, green: 0.95, blue: 0.40),
        ],
        fontDesign: .monospaced,
        colorScheme: .dark
    )

    static let sunset = Palette(
        bg:       Color(red: 0.10, green: 0.06, blue: 0.09),
        bgRaised: Color(red: 0.16, green: 0.09, blue: 0.12),
        card:     Color(red: 0.20, green: 0.12, blue: 0.15),
        stroke:   Color.white.opacity(0.08),
        textPrimary:   Color(red: 0.99, green: 0.96, blue: 0.94),
        textSecondary: Color(red: 0.74, green: 0.62, blue: 0.60),
        gain:   Color(red: 0.98, green: 0.70, blue: 0.30),
        loss:   Color(red: 0.95, green: 0.30, blue: 0.45),
        accent: Color(red: 0.99, green: 0.45, blue: 0.40),
        heroA:  Color(red: 0.85, green: 0.35, blue: 0.30),
        heroB:  Color(red: 0.45, green: 0.18, blue: 0.40),
        chartColors: [
            Color(red: 0.99, green: 0.45, blue: 0.40),
            Color(red: 0.98, green: 0.70, blue: 0.30),
            Color(red: 0.95, green: 0.30, blue: 0.45),
            Color(red: 1.00, green: 0.60, blue: 0.45),
            Color(red: 0.85, green: 0.35, blue: 0.65),
            Color(red: 0.95, green: 0.55, blue: 0.25),
            Color(red: 1.00, green: 0.50, blue: 0.55),
        ],
        fontDesign: .serif,
        colorScheme: .dark
    )

    static let ocean = Palette(
        bg:       Color(red: 0.04, green: 0.08, blue: 0.12),
        bgRaised: Color(red: 0.06, green: 0.12, blue: 0.18),
        card:     Color(red: 0.08, green: 0.15, blue: 0.22),
        stroke:   Color.white.opacity(0.08),
        textPrimary:   Color(red: 0.94, green: 0.97, blue: 0.99),
        textSecondary: Color(red: 0.55, green: 0.66, blue: 0.74),
        gain:   Color(red: 0.20, green: 0.85, blue: 0.80),
        loss:   Color(red: 1.00, green: 0.42, blue: 0.46),
        accent: Color(red: 0.25, green: 0.70, blue: 0.95),
        heroA:  Color(red: 0.10, green: 0.45, blue: 0.62),
        heroB:  Color(red: 0.05, green: 0.22, blue: 0.45),
        chartColors: [
            Color(red: 0.20, green: 0.85, blue: 0.80),
            Color(red: 0.25, green: 0.70, blue: 0.95),
            Color(red: 0.20, green: 0.60, blue: 0.70),
            Color(red: 0.40, green: 0.50, blue: 0.90),
            Color(red: 0.40, green: 0.85, blue: 0.75),
            Color(red: 0.30, green: 0.80, blue: 0.90),
            Color(red: 0.45, green: 0.55, blue: 0.80),
        ],
        fontDesign: .rounded,
        colorScheme: .dark
    )
}

// MARK: - Theme (reads from the current palette)

/// The active design system. Every view reads `Theme.gain`, `Theme.card`, etc.,
/// and those values come from whichever palette is currently selected — so
/// swapping the palette restyles the whole app without touching any view.
enum Theme {
    private(set) static var current: Palette = ThemeChoice.midnight.palette

    static func apply(_ choice: ThemeChoice) { current = choice.palette }

    static var bg: Color            { current.bg }
    static var bgRaised: Color      { current.bgRaised }
    static var card: Color          { current.card }
    static var stroke: Color        { current.stroke }
    static var textPrimary: Color   { current.textPrimary }
    static var textSecondary: Color { current.textSecondary }
    static var gain: Color          { current.gain }
    static var loss: Color          { current.loss }
    static var accent: Color        { current.accent }
    static var chartColors: [Color] { current.chartColors }
    static var fontDesign: Font.Design { current.fontDesign }
    static var colorScheme: ColorScheme { current.colorScheme }

    static var bgGradient: LinearGradient {
        LinearGradient(colors: [bgRaised, bg], startPoint: .top, endPoint: .bottom)
    }

    static var heroGradient: LinearGradient {
        LinearGradient(colors: [current.heroA, current.heroB],
                       startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

// MARK: - Theme manager (persists the choice, drives live switching)

@MainActor
final class ThemeManager: ObservableObject {
    @Published private(set) var selection: ThemeChoice

    private static let key = "themeChoice"

    init() {
        let raw = UserDefaults.standard.string(forKey: Self.key) ?? ""
        let choice = ThemeChoice(rawValue: raw) ?? .midnight
        selection = choice
        Theme.apply(choice)
    }

    func select(_ choice: ThemeChoice) {
        selection = choice
        Theme.apply(choice)
        UserDefaults.standard.set(choice.rawValue, forKey: Self.key)
    }
}

// MARK: - Card style

/// Rounded card container used across the app.
struct CardStyle: ViewModifier {
    var padding: CGFloat = 16
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(Theme.card, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Theme.stroke, lineWidth: 1)
            )
    }
}

extension View {
    func cardStyle(padding: CGFloat = 16) -> some View {
        modifier(CardStyle(padding: padding))
    }
}

import SwiftUI

@main
struct StockSquadApp: App {
    @StateObject private var store = PortfolioStore()
    @StateObject private var theme = ThemeManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .environmentObject(theme)
        }
    }
}

struct ContentView: View {
    @EnvironmentObject private var theme: ThemeManager
    @AppStorage("selectedTab") private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            PortfolioView()
                .tag(0)
                .tabItem { Label("Portfolio", systemImage: "chart.pie.fill") }
            LeaderboardView()
                .tag(1)
                .tabItem { Label("Squad", systemImage: "trophy.fill") }
            ScreenerView()
                .tag(2)
                .tabItem { Label("Scout", systemImage: "binoculars.fill") }
            AppearanceView()
                .tag(3)
                .tabItem { Label("Style", systemImage: "paintpalette.fill") }
        }
        // Rebuild the tab content so every Theme.* read picks up the new palette.
        .id(theme.selection)
        .tint(Theme.accent)
        .fontDesign(Theme.fontDesign)
        .preferredColorScheme(Theme.colorScheme)
    }
}

import SwiftUI
import Combine

// The app's single source of truth. For now it's seeded with sample data.
//
// Stage 3 (shared backend): replace the sample assignments below with network
// calls to your backend (e.g. Supabase). The views won't need to change —
// they only read from this store.

@MainActor
final class PortfolioStore: ObservableObject {
    @Published var members: [Member] = SampleData.members
    @Published var screener: [ScreenerStock] = SampleData.screener

    /// "You" — the first member. Stage 3 ties this to the logged-in user.
    var me: Member { members[0] }

    /// The squad ranked by percentage return, best first.
    var leaderboard: [Member] {
        members.sorted { $0.totalGainPercent > $1.totalGainPercent }
    }
}

import SwiftUI

/// A small row showing live-data status (last updated / updating / needs key)
/// with a manual refresh button. Shown on the Portfolio and Scout tabs.
struct LiveStatusBar: View {
    @EnvironmentObject var store: PortfolioStore

    var body: some View {
        HStack(spacing: 8) {
            if store.needsAPIKey {
                Image(systemName: "key.fill")
                    .font(.caption)
                    .foregroundStyle(.orange)
                Text("Add your Finnhub key in Secrets.swift for live prices")
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
            } else {
                Circle()
                    .fill(store.isRefreshing ? Theme.textSecondary : Theme.gain)
                    .frame(width: 7, height: 7)
                Text(statusText)
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
            }
            Spacer()
            Button {
                Task { await store.refreshQuotes() }
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.caption.weight(.semibold))
            }
            .buttonStyle(.plain)
            .foregroundStyle(Theme.textSecondary)
            .disabled(store.isRefreshing || store.needsAPIKey)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 4)
    }

    private var statusText: String {
        if store.isRefreshing { return "Updating…" }
        if let date = store.lastUpdated {
            return "Updated \(date.formatted(date: .omitted, time: .shortened))"
        }
        return "Pull to refresh for live prices"
    }
}

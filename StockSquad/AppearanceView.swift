import SwiftUI

struct AppearanceView: View {
    @EnvironmentObject var theme: ThemeManager

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bgGradient.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 16) {
                        introCard
                        ForEach(ThemeChoice.allCases) { choice in
                            ThemeCard(choice: choice,
                                      isSelected: choice == theme.selection) {
                                theme.select(choice)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 28)
                }
            }
            .navigationTitle("Style")
        }
    }

    private var introCard: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "paintpalette.fill")
                .foregroundStyle(Theme.accent)
            Text("Pick a look. Each theme changes the colors **and** the font across the whole app — tap one to try it on.")
                .font(.footnote)
                .foregroundStyle(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle(padding: 16)
    }
}

private struct ThemeCard: View {
    let choice: ThemeChoice
    let isSelected: Bool
    let onTap: () -> Void

    // Preview this theme's own palette, regardless of the active theme.
    private var p: Palette { choice.palette }

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 8) {
                    Text(choice.displayName)
                        .font(.title3.weight(.bold))
                        .fontDesign(p.fontDesign)
                        .foregroundStyle(p.textPrimary)
                    Text(choice.fontLabel)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(p.textSecondary)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2)
                        .background(p.bgRaised, in: Capsule())
                    Spacer()
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title3)
                            .foregroundStyle(p.gain)
                    }
                }

                HStack(spacing: 10) {
                    Text("Aa")
                        .font(.system(size: 26, weight: .heavy, design: p.fontDesign))
                        .foregroundStyle(p.textPrimary)
                    pill("+12.4%", color: p.gain, design: p.fontDesign)
                    pill("-3.1%", color: p.loss, design: p.fontDesign)
                    Spacer()
                }

                HStack(spacing: 8) {
                    ForEach(Array(p.chartColors.prefix(6).enumerated()), id: \.offset) { _, c in
                        Circle().fill(c).frame(width: 18, height: 18)
                    }
                }
            }
            .padding(16)
            .background(p.card, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .padding(10)
            .background(p.bg, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(isSelected ? p.accent.opacity(0.8) : p.stroke,
                            lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func pill(_ text: String, color: Color, design: Font.Design) -> some View {
        Text(text)
            .font(.subheadline.weight(.semibold))
            .fontDesign(design)
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.15), in: Capsule())
    }
}

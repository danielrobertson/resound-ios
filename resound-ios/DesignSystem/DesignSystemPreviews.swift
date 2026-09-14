import SwiftUI

/// Preview gallery for the design system: colors, type, WaveMark, and the
/// DoubleBezel container, in both appearances.
private struct DesignSystemGallery: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                brand
                typeSpecimens
                swatches
                bezelCards
            }
            .padding(20)
        }
        .background(Color.appBackground)
    }

    private var brand: some View {
        HStack(spacing: 10) {
            WaveMark()
                .stroke(
                    Color.appPrimary,
                    style: StrokeStyle(lineWidth: 1.6 * 28 / 24, lineCap: .round)
                )
                .frame(width: 28, height: 28)
            Text("resound")
                .font(.display(24, .semibold))
                .foregroundStyle(Color.appForeground)
        }
        .riseIn()
    }

    private var typeSpecimens: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Lessons that continue to resonate.")
                .font(.display(28, .semibold, relativeTo: .largeTitle))
                .foregroundStyle(Color.appForeground)
            Text("Display — Bricolage Grotesque semibold")
                .font(.body(13, .regular, relativeTo: .footnote))
                .foregroundStyle(Color.appMutedForeground)
            Text("Body — Inter regular 17. Capture your first lesson moment — it will resonate here.")
                .font(.body(17))
                .foregroundStyle(Color.appForeground)
            Text("YOUR STUDIO")
                .font(.body(11, .semibold, relativeTo: .caption))
                .kerning(2.2)
                .foregroundStyle(Color.appMutedForeground)
        }
        .riseIn(delay: 0.07)
    }

    private var swatches: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Colors")
                .font(.body(13, .semibold, relativeTo: .footnote))
                .foregroundStyle(Color.appMutedForeground)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 96), spacing: 10)], spacing: 10) {
                swatch("Primary", .appPrimary)
                swatch("PrimaryFg", .appPrimaryForeground)
                swatch("Background", .appBackground)
                swatch("Foreground", .appForeground)
                swatch("Card", .appCard)
                swatch("Muted", .appMuted)
                swatch("MutedFg", .appMutedForeground)
                swatch("Border", .appBorder)
                swatch("Secondary", .appSecondary)
                swatch("Destructive", .appDestructive)
            }
        }
        .riseIn(delay: 0.14)
    }

    private func swatch(_ name: String, _ color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                .fill(color)
                .frame(height: 44)
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                        .strokeBorder(Color.appBorder, lineWidth: 1)
                )
            Text(name)
                .font(.body(11, .medium, relativeTo: .caption2))
                .foregroundStyle(Color.appMutedForeground)
        }
    }

    private var bezelCards: some View {
        VStack(alignment: .leading, spacing: 14) {
            DoubleBezel {
                VStack(alignment: .leading, spacing: 10) {
                    HeroIcon(.microphone, size: 20)
                        .foregroundStyle(Color.appPrimary)
                    Text("Record audio")
                        .font(.display(19, .semibold, relativeTo: .title3))
                        .foregroundStyle(Color.appForeground)
                    Text("Capture a lesson moment with the built-in microphone.")
                        .font(.body(14, .regular, relativeTo: .subheadline))
                        .foregroundStyle(Color.appMutedForeground)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            DoubleBezel(outerRadius: 24, innerPadding: 20) {
                HStack(spacing: 12) {
                    RoundedRectangle(cornerRadius: Radius.xl, style: .continuous)
                        .fill(Color.appMuted)
                        .frame(width: 40, height: 40)
                        .overlay(
                            HeroIcon(.audio, size: 17)
                                .foregroundStyle(Color.appForeground.opacity(0.7))
                        )
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Recording — Aug 3")
                            .font(.body(15, .semibold, relativeTo: .body))
                            .foregroundStyle(Color.appForeground)
                        Text("Audio · 412 KB · Aug 3")
                            .font(.body(12, .regular, relativeTo: .caption))
                            .foregroundStyle(Color.appMutedForeground)
                    }
                    Spacer()
                }
            }
        }
        .riseIn(delay: 0.21)
    }
}

#Preview("Design system — Light") {
    DesignSystemGallery()
        .preferredColorScheme(.light)
}

#Preview("Design system — Dark") {
    DesignSystemGallery()
        .preferredColorScheme(.dark)
}

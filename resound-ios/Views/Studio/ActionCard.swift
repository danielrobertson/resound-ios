import SwiftUI

/// The web studio's `ActionCard`: a double-bezel tray holding an icon
/// square, a title, a one-line description, and a capsule CTA whose
/// trailing arrow lives in its own small circle (the "button-in-button").
struct ActionCard: View {
    var icon: HeroIconName
    var title: String
    var subtitle: String
    var cta: String
    var accent = false
    var action: () -> Void

    var body: some View {
        DoubleBezel(outerRadius: Radius.bezelOuter, padding: 6, innerPadding: 28) {
            VStack(alignment: .leading, spacing: 0) {
                iconSquare

                Text(title)
                    .font(.body(16, .semibold, relativeTo: .headline))
                    .foregroundStyle(Color.appForeground)
                    .padding(.top, 20)

                Text(subtitle)
                    .font(.body(14, relativeTo: .subheadline))
                    .foregroundStyle(Color.appMutedForeground)
                    .padding(.top, 6)

                ctaButton
                    .padding(.top, 28)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var iconSquare: some View {
        HeroIcon(icon, size: 20)
            .foregroundStyle(accent ? Color.appPrimary : Color.appForeground.opacity(0.7))
            .frame(width: 44, height: 44)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(accent ? Color.appPrimary.opacity(0.1) : Color.appMuted)
            )
    }

    private var ctaButton: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Text(cta)
                    .font(.body(14, .medium, relativeTo: .subheadline))

                // Button-in-button: the trailing glyph lives in its own circle.
                HeroIcon(.arrowUpRight, size: 12)
                    .frame(width: 28, height: 28)
                    .background(
                        Circle().fill(
                            accent
                                ? Color.appPrimaryForeground.opacity(0.15)
                                : Color.appForeground.opacity(0.05)
                        )
                    )
            }
            .padding(.leading, 16)
            .padding(.trailing, 6)
            .padding(.vertical, 6)
            .foregroundStyle(accent ? Color.appPrimaryForeground : Color.appForeground.opacity(0.8))
            .background(Capsule().fill(accent ? Color.appPrimary : Color.appMuted))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(cta)
    }
}

#Preview("Action cards") {
    VStack(spacing: 20) {
        ActionCard(
            icon: .microphone,
            title: "Record audio",
            subtitle: "Capture the sound of today's lesson.",
            cta: "Start recording",
            accent: true
        ) {}
        ActionCard(
            icon: .upload,
            title: "Upload a file",
            subtitle: "Video, audio, image, or PDF.",
            cta: "Choose a file"
        ) {}
    }
    .padding(20)
    .background(Color.appBackground)
}

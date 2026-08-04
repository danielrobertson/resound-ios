import SwiftUI

/// The brand's signature "machined tray" container: an outer muted shell with
/// a concentric card inset inside it, finished with a hairline top highlight.
///
/// Mirrors the web studio cards (`studio.tsx`): outer `rounded-[1.75rem]
/// border-border/60 bg-muted/30 p-1.5`, inner `rounded-[1.75rem-0.375rem]
/// bg-card` with `inset 0 1px 0 rgba(255,255,255,0.55)` (0.04 in dark).
struct DoubleBezel<Content: View>: View {
    var outerRadius: CGFloat = Radius.bezelOuter
    var padding: CGFloat = 6
    var innerPadding: CGFloat = 28
    @ViewBuilder var content: () -> Content

    @Environment(\.colorScheme) private var colorScheme

    init(
        outerRadius: CGFloat = Radius.bezelOuter,
        padding: CGFloat = 6,
        innerPadding: CGFloat = 28,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.outerRadius = outerRadius
        self.padding = padding
        self.innerPadding = innerPadding
        self.content = content
    }

    private var innerShape: RoundedRectangle {
        // Concentric with the outer shell: inner radius = outer − padding.
        RoundedRectangle(cornerRadius: outerRadius - padding, style: .continuous)
    }

    private var outerShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: outerRadius, style: .continuous)
    }

    var body: some View {
        content()
            .padding(innerPadding)
            .background(innerShape.fill(Color.appCard))
            .overlay(topHighlight)
            .padding(padding)
            .background(outerShape.fill(Color.appMuted.opacity(0.3)))
            .overlay(outerShape.strokeBorder(Color.appBorder.opacity(0.6), lineWidth: 1))
    }

    /// 1pt inner white line along the top edge of the card — reads as a
    /// catch-light on the bezel. Web: `inset 0 1px 0` white 0.55 / dark 0.04.
    private var topHighlight: some View {
        innerShape
            .strokeBorder(
                Color.white.opacity(colorScheme == .dark ? 0.04 : 0.55),
                lineWidth: 1
            )
            .mask(
                LinearGradient(
                    stops: [
                        .init(color: .white, location: 0),
                        .init(color: .clear, location: 0.2),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .allowsHitTesting(false)
    }
}

import SwiftUI

/// A single soft card replaces the old machined, double-border treatment.
/// The existing inset API is retained for callers that size their content with it.
struct DoubleBezel<Content: View>: View {
    var outerRadius: CGFloat = Radius.bezelOuter
    var padding: CGFloat = 6
    var innerPadding: CGFloat = 28
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(innerPadding + padding)
            .appSurface(radius: outerRadius)
    }
}

private struct AppSurface: ViewModifier {
    var radius: CGFloat
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.colorSchemeContrast) private var contrast

    func body(content: Content) -> some View {
        content
            .background(Color.appCard, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(Color.appBorder.opacity(contrast == .increased ? 1 : 0.55), lineWidth: 1)
                    .allowsHitTesting(false)
            }
            .shadow(color: .black.opacity(colorScheme == .dark ? 0.12 : 0.025), radius: 2, y: 1)
            .shadow(color: .black.opacity(colorScheme == .dark ? 0.1 : 0.025), radius: 16, y: 6)
    }
}

extension View {
    func appSurface(radius: CGFloat = Radius.xl3) -> some View {
        modifier(AppSurface(radius: radius))
    }
}

/// Shared tactile feedback; Reduce Motion keeps the control stationary.
struct AppPressStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.96 : 1)
            .opacity(configuration.isPressed ? 0.75 : 1)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

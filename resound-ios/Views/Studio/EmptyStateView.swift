import SwiftUI

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 8) {
            Text("Keep a moment from your lesson.")
                .font(.system(.title3, weight: .regular))
                .tracking(-0.4)
            Text("Capture it as it happens, or record a reflection afterward.")
                .font(.body)
                .frame(maxWidth: 290)
        }
        .foregroundStyle(.primary)
        .multilineTextAlignment(.center)
        .padding(.horizontal, 8)
    }
}

/// Broad, static color fields keep the library calm and respect Reduce Motion.
struct StudioBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color(uiColor: .systemGroupedBackground)
                Ellipse()
                    .fill(Color(red: 0.67, green: 0.84, blue: 0.93))
                    .frame(width: geometry.size.width * 1.3, height: geometry.size.height * 0.5)
                    .position(x: geometry.size.width * 0.15, y: geometry.size.height * 0.55)
                Ellipse()
                    .fill(Color(red: 0.91, green: 0.73, blue: 0.62))
                    .frame(width: geometry.size.width, height: geometry.size.height * 0.4)
                    .position(x: geometry.size.width * 0.9, y: geometry.size.height * 0.8)
                Ellipse()
                    .fill(Color(red: 0.78, green: 0.79, blue: 0.93))
                    .frame(width: geometry.size.width, height: geometry.size.height * 0.3)
                    .position(x: geometry.size.width * 0.4, y: geometry.size.height)
            }
            .blur(radius: 65)
            .opacity(colorScheme == .dark ? 0.18 : 0.55)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

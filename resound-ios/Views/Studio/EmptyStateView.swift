import SwiftUI

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .fill(Color.appPeach)
                    .frame(width: 112, height: 132)
                    .rotationEffect(.degrees(-12))
                    .offset(x: -24, y: 4)
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .fill(Color.appSage)
                    .frame(width: 112, height: 132)
                    .rotationEffect(.degrees(11))
                    .offset(x: 24, y: -2)
                WaveMark()
                    .stroke(Color.appForeground, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                    .frame(width: 52, height: 52)
                    .frame(width: 112, height: 132)
                    .appSurface(radius: 32)
            }
            .frame(height: 164)
            .accessibilityHidden(true)

            Text("Keep a moment\nfrom your lesson.")
                .font(.display(28, .semibold, relativeTo: .title2))
                .tracking(-0.6)
                .foregroundStyle(Color.appForeground)
                .padding(.top, 28)
            Text("Tap + to record a video or import one from your library.")
                .font(.body(15, relativeTo: .body))
                .foregroundStyle(Color.appMutedForeground)
                .frame(maxWidth: 270)
                .padding(.top, 12)
        }
        .multilineTextAlignment(.center)
        .padding(.horizontal, 16)
        .padding(.vertical, 32)
    }
}

/// A neutral canvas with faint edge color; stronger accents belong to actions and feature cards.
struct StudioBackground: View {
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.appBackground
                if !reduceTransparency {
                    RadialGradient(colors: [Color.appSky.opacity(0.16), .clear],
                                   center: .topTrailing, startRadius: 0,
                                   endRadius: geometry.size.width * 1.05)
                    RadialGradient(colors: [Color.appSage.opacity(0.14), .clear],
                                   center: .bottomTrailing, startRadius: 0,
                                   endRadius: geometry.size.width * 1.15)
                }
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

import SwiftUI

extension Animation {
    /// Settling ease for state changes — web `cubic-bezier(0.32, 0.72, 0, 1)`
    /// at ~420ms.
    static let settle = Animation.timingCurve(0.32, 0.72, 0, 1, duration: 0.42)

    /// Entrance ease — web `.rise-in`: `cubic-bezier(0.16, 1, 0.3, 1)` 700ms.
    static let rise = Animation.timingCurve(0.16, 1, 0.3, 1, duration: 0.7)
}

/// Gentle entrance: fades in from opacity 0 and rises 12pt, like the web's
/// `.rise-in` keyframes. Becomes a no-op under Reduce Motion.
private struct RiseIn: ViewModifier {
    var delay: Double

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isShown = false

    func body(content: Content) -> some View {
        content
            .opacity(isShown || reduceMotion ? 1 : 0)
            .offset(y: isShown || reduceMotion ? 0 : 12)
            .onAppear {
                guard !reduceMotion else { return }
                withAnimation(.rise.delay(delay)) {
                    isShown = true
                }
            }
    }
}

extension View {
    /// Staggered entrance reveal; pass increasing delays (70–90ms steps) for
    /// sibling views. Content appears immediately when Reduce Motion is on.
    func riseIn(delay: Double = 0) -> some View {
        modifier(RiseIn(delay: delay))
    }
}

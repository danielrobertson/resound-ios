import SwiftUI

/// Minimal, thin-stroke sound-wave logo mark, matching the web `WaveMark`
/// SVG: a 24×24 viewBox with four round-cap vertical lines at x = 4/9/14/19,
/// heights 5/15/9/19, centered on y = 12.
///
/// Consumers stroke the shape themselves, e.g.:
/// `WaveMark().stroke(style: .init(lineWidth: 1.6 * size / 24, lineCap: .round))`
struct WaveMark: Shape {
    /// The four bars as (x, height) in 24×24 unit space.
    private static let bars: [(x: CGFloat, height: CGFloat)] = [
        (4, 5), (9, 15), (14, 9), (19, 19),
    ]

    func path(in rect: CGRect) -> Path {
        let scaleX = rect.width / 24
        let scaleY = rect.height / 24
        var path = Path()
        for bar in Self.bars {
            let x = rect.minX + bar.x * scaleX
            let midY = rect.minY + 12 * scaleY
            let halfHeight = bar.height / 2 * scaleY
            path.move(to: CGPoint(x: x, y: midY - halfHeight))
            path.addLine(to: CGPoint(x: x, y: midY + halfHeight))
        }
        return path
    }
}

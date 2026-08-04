import SwiftUI

/// Live input levels as round-capped vertical bars, matching the web's
/// waveform geometry (5pt bars, 5pt gaps, 2.5pt corners). Newest levels are
/// right-aligned so the trace appears to scroll left as it records; silence
/// still reads as a row of dots via the minimum bar height.
struct LiveWaveformView: View {
    var levels: [Float]

    private static let barWidth: CGFloat = 5
    private static let gap: CGFloat = 5
    private static let cornerRadius: CGFloat = 2.5
    /// A bar this short renders as a dot (height == width with round corners).
    private static let minHeight: CGFloat = 5

    var body: some View {
        TimelineView(.animation) { _ in
            Canvas { context, size in
                let step = Self.barWidth + Self.gap
                let capacity = max(Int(size.width / step), 0)
                guard capacity > 0 else { return }

                let visible = levels.suffix(capacity)
                let midY = size.height / 2
                var x = size.width - Self.barWidth

                for level in visible.reversed() {
                    let height = max(Self.minHeight, CGFloat(level) * size.height)
                    let rect = CGRect(
                        x: x,
                        y: midY - height / 2,
                        width: Self.barWidth,
                        height: height
                    )
                    context.fill(
                        Path(roundedRect: rect, cornerRadius: Self.cornerRadius),
                        with: .color(.appPrimary)
                    )
                    x -= step
                    if x < -Self.barWidth { break }
                }
            }
        }
        .accessibilityElement()
        .accessibilityLabel("Live audio level")
    }
}

#Preview("Live waveform") {
    LiveWaveformView(levels: WaveformSampler.placeholder)
        .frame(height: 120)
        .padding(24)
        .background(Color.appBackground)
}

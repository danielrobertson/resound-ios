import SwiftUI

/// The 56-bar static waveform (web landing-page geometry): round-capped
/// bars spread across the width, painted primary up to the playback
/// position and muted beyond it. Tap or drag anywhere to seek.
struct StaticWaveformView: View {
    var samples: [Float]
    /// Played fraction in 0...1.
    var progress: Double
    /// Called with the target fraction (0...1) as the user taps or drags.
    var onSeek: (Double) -> Void

    var body: some View {
        GeometryReader { geometry in
            Canvas { context, size in
                let count = samples.count
                guard count > 0 else { return }

                let step = size.width / CGFloat(count)
                let barWidth = min(5, step * 0.55)
                let midY = size.height / 2
                let playedBars = progress * Double(count)

                for index in 0..<count {
                    let level = CGFloat(max(samples[index], 0.06))
                    let height = max(barWidth, level * size.height)
                    let x = CGFloat(index) * step + (step - barWidth) / 2
                    let rect = CGRect(x: x, y: midY - height / 2, width: barWidth, height: height)
                    let played = Double(index) + 0.5 <= playedBars

                    context.fill(
                        Path(roundedRect: rect, cornerRadius: barWidth / 2),
                        with: .color(played ? Color.appPrimary : Color.appMutedForeground.opacity(0.35))
                    )
                }
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let width = max(geometry.size.width, 1)
                        onSeek(min(max(value.location.x / width, 0), 1))
                    }
            )
        }
        .accessibilityElement()
        .accessibilityLabel("Playback position")
        .accessibilityValue("\(Int((progress * 100).rounded())) percent")
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: onSeek(min(progress + 0.05, 1))
            case .decrement: onSeek(max(progress - 0.05, 0))
            @unknown default: break
            }
        }
    }
}

#Preview("Static waveform") {
    StaticWaveformView(samples: WaveformSampler.placeholder, progress: 0.4) { _ in }
        .frame(height: 88)
        .padding(24)
        .background(Color.appBackground)
}

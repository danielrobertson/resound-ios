import AVFoundation

/// Reduces an audio file to a fixed number of peak-normalized RMS bars for
/// the static waveform view. Results are cached, and the expensive read
/// happens off the main actor.
///
/// `nonisolated` opts the whole type out of the project's MainActor default
/// isolation — everything here is pure computation plus a thread-safe cache.
nonisolated enum WaveformSampler {

    enum SamplingError: Error {
        case bufferAllocationFailed
    }

    /// Web-parity bar count (see the 56-bar hero waveform in the web app).
    static let defaultBarCount = 56

    /// Returns exactly `barCount` values in 0...1 — the RMS of each equal
    /// slice of the file, normalized so the loudest bar is 1. An all-silent
    /// file yields all zeros.
    static func samples(from url: URL, barCount: Int = defaultBarCount) async throws -> [Float] {
        let key = cacheKey(url: url, barCount: barCount)
        if let cached = cache.object(forKey: key) {
            return cached.values
        }

        let values = try await Task.detached(priority: .userInitiated) {
            try compute(url: url, barCount: barCount)
        }.value

        cache.setObject(LevelsBox(values), forKey: key)
        return values
    }

    /// Organic-looking 56-bar curve for previews and placeholders, derived
    /// from the web landing page's three-sine WAVE_BARS aesthetic and
    /// normalized into the 0.12...1 band so no bar collapses to nothing.
    static let placeholder: [Float] = {
        let count = 56
        let raw: [Float] = (0..<count).map { i in
            let t = Float(i) / Float(count - 1)
            let value = sin(t * .pi * 3.2) * 0.55
                + sin(t * .pi * 7.7) * 0.28
                + sin(t * .pi * 1.3) * 0.35
            return abs(value)
        }
        let peak = max(raw.max() ?? 1, .ulpOfOne)
        return raw.map { 0.12 + ($0 / peak) * 0.88 }
    }()

    // MARK: - Cache

    private final class LevelsBox: Sendable {
        let values: [Float]
        init(_ values: [Float]) { self.values = values }
    }

    // NSCache is thread-safe but not Sendable; the annotation opts the
    // shared instance out of static-variable concurrency checking.
    nonisolated(unsafe) private static let cache = NSCache<NSString, LevelsBox>()

    private static func cacheKey(url: URL, barCount: Int) -> NSString {
        "\(url.path)#\(barCount)" as NSString
    }

    // MARK: - Computation

    private static func compute(url: URL, barCount: Int) throws -> [Float] {
        precondition(barCount > 0, "barCount must be positive")

        let file = try AVAudioFile(forReading: url)
        let format = file.processingFormat
        let totalFrames = Int(file.length)
        guard totalFrames > 0 else {
            return [Float](repeating: 0, count: barCount)
        }

        let framesPerBar = max(1, totalFrames / barCount)
        var squareSums = [Double](repeating: 0, count: barCount)
        var frameCounts = [Int](repeating: 0, count: barCount)

        let chunkCapacity: AVAudioFrameCount = 16_384
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: chunkCapacity) else {
            throw SamplingError.bufferAllocationFailed
        }
        let channelCount = Int(format.channelCount)

        var frameOffset = 0
        while frameOffset < totalFrames {
            try file.read(into: buffer, frameCount: chunkCapacity)
            let frames = Int(buffer.frameLength)
            if frames == 0 { break }
            guard let channelData = buffer.floatChannelData else { break }

            for frame in 0..<frames {
                var sample: Float = 0
                for channel in 0..<channelCount {
                    sample += channelData[channel][frame]
                }
                sample /= Float(channelCount)

                let bar = min((frameOffset + frame) / framesPerBar, barCount - 1)
                squareSums[bar] += Double(sample) * Double(sample)
                frameCounts[bar] += 1
            }
            frameOffset += frames
        }

        var bars: [Float] = (0..<barCount).map { bar in
            frameCounts[bar] > 0 ? Float(sqrt(squareSums[bar] / Double(frameCounts[bar]))) : 0
        }

        // Peak-normalize; an all-silence file stays all zeros.
        if let peak = bars.max(), peak > 0 {
            bars = bars.map { min($0 / peak, 1) }
        }
        return bars
    }
}

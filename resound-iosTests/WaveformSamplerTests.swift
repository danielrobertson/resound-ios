import AVFoundation
import Testing

@testable import resound_ios

struct WaveformSamplerTests {

    /// Writes a 1-second 440 Hz mono sine (with a linear fade-in so bucket
    /// RMS varies) to a temp .caf and returns its URL. The AVAudioFile is
    /// scoped inside so the file is flushed/closed before reading.
    private func makeSineFile() throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("caf")

        let sampleRate = 44_100.0
        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1) else {
            throw NSError(domain: "WaveformSamplerTests", code: 1)
        }
        let frameCount = AVAudioFrameCount(sampleRate)

        do {
            let file = try AVAudioFile(forWriting: url, settings: format.settings)
            guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
                throw NSError(domain: "WaveformSamplerTests", code: 2)
            }
            buffer.frameLength = frameCount
            let samples = buffer.floatChannelData![0]
            for i in 0..<Int(frameCount) {
                let t = Double(i) / Double(frameCount)
                let envelope = 0.2 + 0.8 * t // fade-in so bars differ
                let value = sin(2.0 * .pi * 440.0 * Double(i) / sampleRate) * envelope * 0.8
                samples[i] = Float(value)
            }
            try file.write(from: buffer)
        }

        return url
    }

    @Test func samplesFromSineFileProduceNormalizedBars() async throws {
        let url = try makeSineFile()
        defer { try? FileManager.default.removeItem(at: url) }

        let samples = try await WaveformSampler.samples(from: url)

        #expect(samples.count == 56)
        #expect(samples.allSatisfy { $0 >= 0 && $0 <= 1 })
        #expect(samples.max() == 1)

        let mean = samples.reduce(0, +) / Float(samples.count)
        let variance = samples.reduce(Float(0)) { $0 + ($1 - mean) * ($1 - mean) } / Float(samples.count)
        #expect(variance > 0)
    }

    @Test func repeatedCallsReturnSameValues() async throws {
        let url = try makeSineFile()
        defer { try? FileManager.default.removeItem(at: url) }

        let first = try await WaveformSampler.samples(from: url)
        let second = try await WaveformSampler.samples(from: url)
        #expect(first == second)
    }

    @Test func placeholderHas56ValuesInRange() {
        let placeholder = WaveformSampler.placeholder
        #expect(placeholder.count == 56)
        #expect(placeholder.allSatisfy { $0 >= 0 && $0 <= 1 })

        let mean = placeholder.reduce(0, +) / Float(placeholder.count)
        let variance = placeholder.reduce(Float(0)) { $0 + ($1 - mean) * ($1 - mean) } / Float(placeholder.count)
        #expect(variance > 0)
    }
}

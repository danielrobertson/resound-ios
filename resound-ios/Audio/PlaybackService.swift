import AVFoundation
import Observation

/// Wraps a single `AVPlayer` for audio and imported-video playback. The
/// player is exposed so `VideoPlayer(player:)` can render video directly;
/// audio UIs drive the transport through the published properties.
@MainActor
@Observable
final class PlaybackService {

    /// Exposed for `VideoPlayer(player:)`.
    let player = AVPlayer()

    private(set) var isPlaying = false
    private(set) var currentTime: TimeInterval = 0
    private(set) var duration: TimeInterval = 0

    var progress: Double {
        duration > 0 ? currentTime / duration : 0
    }

    @ObservationIgnored private var timeObserver: Any?
    @ObservationIgnored private var endObserver: NSObjectProtocol?

    deinit {
        // deinit is nonisolated but may touch stored properties; the player
        // tolerates observer removal from any thread.
        if let timeObserver {
            player.removeTimeObserver(timeObserver)
        }
        if let endObserver {
            NotificationCenter.default.removeObserver(endObserver)
        }
    }

    // MARK: - Loading

    /// Replaces the current item with `url`, resolves its duration, and
    /// installs progress + end-of-playback observers.
    func load(url: URL) async {
        teardownObservers()
        player.pause()
        isPlaying = false
        currentTime = 0
        duration = 0

        let asset = AVURLAsset(url: url)
        let item = AVPlayerItem(asset: asset)
        player.replaceCurrentItem(with: item)

        if let assetDuration = try? await asset.load(.duration), assetDuration.isNumeric {
            duration = assetDuration.seconds
        }

        installObservers(for: item)
    }

    // MARK: - Transport

    func togglePlay() {
        if isPlaying {
            player.pause()
            isPlaying = false
        } else {
            try? AudioSessionConfig.activateForPlayback()
            player.play()
            isPlaying = true
        }
    }

    func seek(to time: TimeInterval) {
        let clamped = max(0, duration > 0 ? min(time, duration) : time)
        let target = CMTime(seconds: clamped, preferredTimescale: 600)
        player.seek(to: target, toleranceBefore: .zero, toleranceAfter: .zero)
        currentTime = clamped
    }

    /// Pauses playback and tears down all observers. Call before letting
    /// the service go out of scope; `deinit` covers anything missed.
    func stop() {
        player.pause()
        isPlaying = false
        teardownObservers()
    }

    // MARK: - Observers

    private func installObservers(for item: AVPlayerItem) {
        let interval = CMTime(seconds: 0.05, preferredTimescale: 600)
        timeObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            MainActor.assumeIsolated {
                guard let self, time.isNumeric else { return }
                self.currentTime = time.seconds
            }
        }

        endObserver = NotificationCenter.default.addObserver(
            forName: AVPlayerItem.didPlayToEndTimeNotification,
            object: item,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self else { return }
                self.isPlaying = false
                self.currentTime = 0
                self.player.seek(to: .zero)
            }
        }
    }

    private func teardownObservers() {
        if let timeObserver {
            player.removeTimeObserver(timeObserver)
            self.timeObserver = nil
        }
        if let endObserver {
            NotificationCenter.default.removeObserver(endObserver)
            self.endObserver = nil
        }
    }
}

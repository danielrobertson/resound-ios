import AVFoundation
import Observation

/// Drives microphone capture with `AVAudioRecorder`: permission flow,
/// pause/resume, live metering for the waveform, and finalizing a temp
/// `.m4a` for the caller to persist.
@MainActor
@Observable
final class AudioRecorderService {

    enum State: Equatable {
        case idle
        case denied
        case recording
        case paused
    }

    private(set) var state: State = .idle
    private(set) var elapsed: TimeInterval = 0
    /// Rolling window of linear meter levels (0...1), newest last,
    /// capped at `Self.levelWindowSize` values.
    private(set) var levels: [Float] = []

    static let levelWindowSize = 140

    @ObservationIgnored private var recorder: AVAudioRecorder?
    @ObservationIgnored private var meterTimer: Timer?
    @ObservationIgnored private var fileURL: URL?
    @ObservationIgnored private var interruptionObserver: (any NSObjectProtocol)?

    private static let meterInterval: TimeInterval = 1.0 / 30.0
    private static let silenceFloorDB: Float = -60

    init() {
        // A phone call or Siri shouldn't lose the take: when the system
        // interrupts the session mid-recording, settle into .paused so the
        // user can resume afterwards. (The system has already halted
        // capture by the time this fires.)
        interruptionObserver = NotificationCenter.default.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            let type = (notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt)
                .flatMap(AVAudioSession.InterruptionType.init)
            guard type == .began else { return }
            MainActor.assumeIsolated {
                guard let self, self.state == .recording else { return }
                self.pause()
            }
        }
    }

    deinit {
        meterTimer?.invalidate()
        if let interruptionObserver {
            NotificationCenter.default.removeObserver(interruptionObserver)
        }
    }

    // MARK: - Lifecycle

    /// Requests microphone permission and, if granted, activates the audio
    /// session and begins recording to a fresh temp file. On denial the
    /// service settles in `.denied` without throwing.
    func requestPermissionAndStart() async throws {
        guard state == .idle || state == .denied else { return }

        let granted = await AVAudioApplication.requestRecordPermission()
        guard granted else {
            state = .denied
            return
        }

        try AudioSessionConfig.activateForRecording()

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("m4a")
        let settings: [String: Any] = [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVSampleRateKey: 44_100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
        ]

        let recorder = try AVAudioRecorder(url: url, settings: settings)
        recorder.isMeteringEnabled = true
        recorder.record()

        self.recorder = recorder
        fileURL = url
        elapsed = 0
        levels = []
        state = .recording
        startMeterTimer()
    }

    func pause() {
        guard state == .recording, let recorder else { return }
        recorder.pause()
        stopMeterTimer()
        state = .paused
    }

    func resume() {
        guard state == .paused, let recorder else { return }
        recorder.record()
        startMeterTimer()
        state = .recording
    }

    /// Finalizes the recording and returns the temp file URL plus the
    /// captured duration. Returns `nil` unless recording or paused.
    func stop() -> (url: URL, duration: TimeInterval)? {
        guard state == .recording || state == .paused,
              let recorder, let url = fileURL else { return nil }

        let duration = elapsed
        recorder.stop()
        stopMeterTimer()
        AudioSessionConfig.deactivate()

        self.recorder = nil
        fileURL = nil
        state = .idle
        return (url: url, duration: duration)
    }

    /// Stops (if needed), deletes the temp file, and resets all published
    /// state including the level window.
    func discard() {
        if let result = stop() {
            try? FileManager.default.removeItem(at: result.url)
        }
        elapsed = 0
        levels = []
        state = .idle
    }

    // MARK: - Metering

    private func startMeterTimer() {
        stopMeterTimer()
        // The timer fires on the main run loop, so hopping back into the
        // @MainActor-isolated service via `assumeIsolated` is safe.
        let timer = Timer(timeInterval: Self.meterInterval, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.tickMeter()
            }
        }
        timer.tolerance = Self.meterInterval / 4
        RunLoop.main.add(timer, forMode: .common)
        meterTimer = timer
    }

    private func stopMeterTimer() {
        meterTimer?.invalidate()
        meterTimer = nil
    }

    private func tickMeter() {
        guard state == .recording, let recorder else { return }
        recorder.updateMeters()

        let db = recorder.averagePower(forChannel: 0)
        let linear: Float
        if db < Self.silenceFloorDB {
            linear = 0
        } else {
            linear = min(max(pow(10, db / 20), 0), 1)
        }

        levels.append(linear)
        if levels.count > Self.levelWindowSize {
            levels.removeFirst(levels.count - Self.levelWindowSize)
        }
        elapsed = recorder.currentTime
    }
}

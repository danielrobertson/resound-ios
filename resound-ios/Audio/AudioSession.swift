import AVFoundation

/// Thin wrapper around `AVAudioSession` configuration so the recording and
/// playback services share one place for category/activation policy.
enum AudioSessionConfig {

    /// Configures the shared session for microphone capture with speaker
    /// output and Bluetooth headset support, then activates it.
    static func activateForRecording() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, options: [.defaultToSpeaker, .allowBluetoothHFP])
        try session.setActive(true)
    }

    /// Configures the shared session for playback and activates it.
    static func activateForPlayback() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playback)
        try session.setActive(true)
    }

    /// Deactivates the shared session, letting other apps resume their audio.
    /// Deactivation failures are intentionally swallowed — there is nothing
    /// actionable for the caller when hand-back fails.
    static func deactivate() {
        try? AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
    }
}

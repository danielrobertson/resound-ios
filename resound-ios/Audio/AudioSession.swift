import AVFoundation

/// Enables video sound even when the device is in silent mode.
enum AudioSessionConfig {
    static func activateForPlayback() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playback)
        try session.setActive(true)
    }
}

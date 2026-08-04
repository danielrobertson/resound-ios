import Foundation
import SwiftData
import UniformTypeIdentifiers

/// The broad category of a recording, mirroring the web app's MIME-prefix rule
/// (`audio/*` → audio, `video/*` → video, anything else → file).
enum RecordingKind: String, Codable, CaseIterable {
    case audio
    case video
    case file

    init(contentType: UTType) {
        if contentType.conforms(to: .audio) {
            self = .audio
        } else if contentType.conforms(to: .movie) || contentType.conforms(to: .video) {
            self = .video
        } else {
            self = .file
        }
    }
}

/// A captured or imported lesson moment.
///
/// The media blob lives on disk in the store's directory; only the *relative*
/// `fileName` is persisted — the app container path changes between launches,
/// so absolute paths must never be stored.
@Model
final class Recording {
    @Attribute(.unique) var id: UUID
    var kindRaw: String
    var title: String
    /// UTType identifier, e.g. `"com.apple.m4a-audio"`.
    var contentType: String
    /// Size in bytes of the media file on disk.
    var size: Int64
    /// Media duration in seconds; nil for non-audiovisual files.
    var duration: TimeInterval?
    var createdAt: Date
    /// Relative file name inside the store's directory — never an absolute path.
    var fileName: String
    /// Reserved for future backend sync; "local" until then.
    var syncState: String

    var kind: RecordingKind {
        get { RecordingKind(rawValue: kindRaw) ?? .file }
        set { kindRaw = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        kind: RecordingKind,
        title: String,
        contentType: String,
        size: Int64,
        duration: TimeInterval? = nil,
        createdAt: Date = .now,
        fileName: String,
        syncState: String = "local"
    ) {
        self.id = id
        self.kindRaw = kind.rawValue
        self.title = title
        self.contentType = contentType
        self.size = size
        self.duration = duration
        self.createdAt = createdAt
        self.fileName = fileName
        self.syncState = syncState
    }
}

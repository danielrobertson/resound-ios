import Foundation
import SwiftData
import UniformTypeIdentifiers

/// New recordings are videos. Legacy kindRaw values remain stored but are hidden.
enum RecordingKind: String, Codable {
    case video
}

/// Where a recording stands with the backend.
///
/// `local` covers both "never uploaded" and "uploaded but edited since" —
/// either way it needs a push. Whether that push includes the media blob is
/// answered by `storagePath`, not by this.
enum SyncState: String, Codable, CaseIterable {
    /// Has local changes the server hasn't seen.
    case local
    /// A push is in flight.
    case uploading
    /// Server matches what's on disk.
    case synced
    /// Last push failed; retried on next launch.
    case failed
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
    /// Video UTType identifier.
    var contentType: String
    /// Size in bytes of the media file on disk.
    var size: Int64
    /// Video duration in seconds, when available.
    var duration: TimeInterval?
    var createdAt: Date
    /// Last local mutation, pushed as the document's `updatedAt` so the
    /// server can tell which copy is newer.
    var updatedAt: Date = Date.now
    /// Relative file name inside the store's directory — never an absolute path.
    var fileName: String
    /// Backing store for `syncState`.
    var syncStateRaw: String = SyncState.local.rawValue
    /// Object path in Cloud Storage once the blob is up; nil until then.
    /// Its presence is what distinguishes "needs a full upload" from
    /// "needs a metadata-only push".
    var storagePath: String?
    /// User-assigned tags, e.g. "Scales", "Jazz". Order is user-defined.
    var tags: [String] = []
    /// Retained only to preserve previously saved data. Not exposed or synced.
    var notes: String = ""

    var kind: RecordingKind? {
        get { RecordingKind(rawValue: kindRaw) }
        set { kindRaw = newValue?.rawValue ?? kindRaw }
    }

    var syncState: SyncState {
        get { SyncState(rawValue: syncStateRaw) ?? .local }
        set { syncStateRaw = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        kind: RecordingKind,
        title: String,
        contentType: String,
        size: Int64,
        duration: TimeInterval? = nil,
        createdAt: Date = .now,
        updatedAt: Date = .now,
        fileName: String,
        syncState: SyncState = .local,
        storagePath: String? = nil,
        tags: [String] = []
    ) {
        self.id = id
        self.kindRaw = kind.rawValue
        self.title = title
        self.contentType = contentType
        self.size = size
        self.duration = duration
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.fileName = fileName
        self.syncStateRaw = syncState.rawValue
        self.storagePath = storagePath
        self.tags = tags
    }
}

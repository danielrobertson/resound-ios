import FirebaseFirestore
import FirebaseStorage
import Foundation

/// The parts of a `Recording` that go to the server, lifted out of SwiftData
/// so a push can't observe the model mutating mid-flight.
struct RecordingSnapshot: Sendable {
    let id: UUID
    let kind: String
    let title: String
    let contentType: String
    let size: Int64
    let duration: TimeInterval?
    let createdAt: Date
    let updatedAt: Date
    let fileName: String
    let tags: [String]
    let notes: String

    init(_ recording: Recording) {
        id = recording.id
        kind = recording.kind.rawValue
        title = recording.title
        contentType = recording.contentType
        size = recording.size
        duration = recording.duration
        createdAt = recording.createdAt
        updatedAt = recording.updatedAt
        fileName = recording.fileName
        tags = recording.tags
        notes = recording.notes
    }
}

/// Transport for the user's private cloud vault. Holds no state and makes no
/// decisions about *when* to sync — `RecordingStore` owns that.
///
/// The layout mirrors the deployed security rules exactly; changing either
/// side means changing `firestore.rules` and `storage.rules` too:
///
///     Storage    users/{uid}/recordings/{fileName}
///     Firestore  users/{uid}/recordings/{id}
///
/// This is a one-way push. Nothing reads back down yet — restoring a vault
/// onto a fresh install is separate work, and worth noting that an anonymous
/// uid can't be recovered after the app is deleted anyway.
struct SyncService: Sendable {
    /// Matches the 500 MB ceiling in `storage.rules`. Checked locally so an
    /// oversized import fails fast with a clear reason instead of burning an
    /// upload and getting a permission error at the end.
    static let maxUploadBytes: Int64 = 500 * 1024 * 1024

    enum SyncError: LocalizedError {
        case fileTooLarge(Int64)
        case fileMissing(String)

        var errorDescription: String? {
            switch self {
            case .fileTooLarge(let bytes):
                "This file is \(Format.size(bytes)), over the \(Format.size(SyncService.maxUploadBytes)) backup limit."
            case .fileMissing(let name):
                "The media file \(name) is missing from this device."
            }
        }
    }

    /// Uploads the media blob and returns its Storage object path.
    func uploadMedia(_ snapshot: RecordingSnapshot, from fileURL: URL, uid: String) async throws -> String {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            throw SyncError.fileMissing(snapshot.fileName)
        }
        guard snapshot.size <= Self.maxUploadBytes else {
            throw SyncError.fileTooLarge(snapshot.size)
        }

        let path = Self.storagePath(uid: uid, fileName: snapshot.fileName)
        let metadata = StorageMetadata()
        metadata.contentType = snapshot.contentType

        _ = try await Storage.storage().reference(withPath: path)
            .putFileAsync(from: fileURL, metadata: metadata)
        return path
    }

    /// Writes the metadata document, creating or overwriting it wholesale.
    func pushMetadata(_ snapshot: RecordingSnapshot, storagePath: String?, uid: String) async throws {
        var data: [String: Any] = [
            "id": snapshot.id.uuidString,
            "kind": snapshot.kind,
            "title": snapshot.title,
            "contentType": snapshot.contentType,
            "size": snapshot.size,
            "createdAt": Timestamp(date: snapshot.createdAt),
            "updatedAt": Timestamp(date: snapshot.updatedAt),
            "fileName": snapshot.fileName,
            "tags": snapshot.tags,
            "notes": snapshot.notes,
        ]
        // Absent rather than null for non-audiovisual files, so queries can
        // use `where duration exists` instead of filtering nulls out.
        if let duration = snapshot.duration {
            data["duration"] = duration
        }
        if let storagePath {
            data["storagePath"] = storagePath
        }

        try await Self.document(uid: uid, id: snapshot.id).setData(data)
    }

    /// Removes the blob and the document. A blob that's already gone is not
    /// an error — the document is what the studio reads, so it must go even
    /// if Storage cleanup already happened or never got that far.
    func deleteRemote(id: UUID, storagePath: String?, uid: String) async throws {
        if let storagePath {
            do {
                try await Storage.storage().reference(withPath: storagePath).delete()
            } catch {
                let code = StorageErrorCode(rawValue: (error as NSError).code)
                guard code == .objectNotFound else { throw error }
            }
        }
        try await Self.document(uid: uid, id: id).delete()
    }

    // MARK: - Paths

    static func storagePath(uid: String, fileName: String) -> String {
        "users/\(uid)/recordings/\(fileName)"
    }

    private static func document(uid: String, id: UUID) -> DocumentReference {
        Firestore.firestore()
            .collection("users").document(uid)
            .collection("recordings").document(id.uuidString)
    }
}

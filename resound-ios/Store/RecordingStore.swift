import AVFoundation
import Foundation
import Observation
import SwiftData
import UniformTypeIdentifiers

/// Owns the recordings media directory and all mutations of `Recording` rows.
///
/// Media blobs live on disk in `directory`; the database stores only the
/// relative `fileName`, because the app container path changes between
/// launches.
@MainActor
@Observable
final class RecordingStore {
    let directory: URL

    @ObservationIgnored
    private let modelContext: ModelContext

    @ObservationIgnored
    private let auth: AuthService?

    @ObservationIgnored
    private let sync: SyncService?

    /// Rows with a push in flight, so a burst of edits (typing in the notes
    /// field, adding three tags) doesn't start overlapping uploads for one
    /// recording. The trailing edit is picked up by the retry pass.
    @ObservationIgnored
    private var inFlight: Set<UUID> = []

    /// - Parameters:
    ///   - modelContext: The SwiftData context to insert/delete rows in.
    ///   - directory: Where media files live. Defaults to
    ///     `Application Support/Recordings`, created on init.
    ///   - auth: Supplies the uid every backend path is scoped to. Nil in
    ///     tests and in checkouts without Firebase — the store then behaves
    ///     exactly as it did before sync existed.
    ///   - sync: Transport for pushes. Nil alongside `auth`.
    init(
        modelContext: ModelContext,
        directory: URL? = nil,
        auth: AuthService? = nil,
        sync: SyncService? = nil
    ) {
        self.modelContext = modelContext
        self.directory = directory
            ?? URL.applicationSupportDirectory.appending(path: "Recordings", directoryHint: .isDirectory)
        self.auth = auth
        self.sync = sync
        try? FileManager.default.createDirectory(at: self.directory, withIntermediateDirectories: true)
    }

    /// Absolute on-disk location of a recording's media file.
    func url(for recording: Recording) -> URL {
        directory.appending(path: recording.fileName, directoryHint: .notDirectory)
    }

    /// Copies `sourceURL` into the store's directory as `<uuid>.<ext>`,
    /// reads its byte size, and inserts a new `Recording` row.
    @discardableResult
    func create(
        copying sourceURL: URL,
        kind: RecordingKind,
        title: String,
        contentType: UTType,
        duration: TimeInterval?
    ) throws -> Recording {
        let id = UUID()
        let ext = contentType.preferredFilenameExtension ?? sourceURL.pathExtension
        let fileName = ext.isEmpty ? id.uuidString : "\(id.uuidString).\(ext)"
        let destination = directory.appending(path: fileName, directoryHint: .notDirectory)

        try FileManager.default.copyItem(at: sourceURL, to: destination)
        let size = Int64((try? destination.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0)

        let recording = Recording(
            id: id,
            kind: kind,
            title: title,
            contentType: contentType.identifier,
            size: size,
            duration: duration,
            fileName: fileName
        )
        modelContext.insert(recording)
        do {
            try modelContext.save()
        } catch {
            modelContext.delete(recording)
            try? FileManager.default.removeItem(at: destination)
            throw error
        }
        schedulePush(recording)
        return recording
    }

    /// Imports an external file (Files app, photo library export, …):
    /// wraps security-scoped access, derives kind/title/duration, then
    /// delegates to `create(copying:...)`.
    @discardableResult
    func importFile(at url: URL) async throws -> Recording {
        let accessing = url.startAccessingSecurityScopedResource()
        defer {
            if accessing { url.stopAccessingSecurityScopedResource() }
        }

        let contentType = (try? url.resourceValues(forKeys: [.contentTypeKey]))?.contentType
            ?? UTType(filenameExtension: url.pathExtension)
            ?? .data
        let kind = RecordingKind(contentType: contentType)
        let title = Self.importTitle(from: url.deletingPathExtension().lastPathComponent)

        var duration: TimeInterval?
        if kind == .audio || kind == .video {
            let asset = AVURLAsset(url: url)
            if let time = try? await asset.load(.duration), time.isNumeric {
                duration = time.seconds
            }
        }

        return try create(
            copying: url,
            kind: kind,
            title: title,
            contentType: contentType,
            duration: duration
        )
    }

    /// Camera-roll names ("IMG_1234", "vid 0042") say nothing about the
    /// lesson, so imports falling back on them get a dated title instead
    /// ("Import — Aug 3"). Anything human-looking passes through trimmed.
    static func importTitle(from fileName: String, date: Date = .now) -> String {
        let trimmed = fileName.trimmingCharacters(in: .whitespacesAndNewlines)
        let cameraPattern = "^(IMG|VID|DSC|PXL|MOV)[-_ ]?[0-9]+$"
        let looksLikeCameraName = trimmed.range(
            of: cameraPattern,
            options: [.regularExpression, .caseInsensitive]
        ) != nil
        if trimmed.isEmpty || looksLikeCameraName {
            return "Import — \(Format.shortDate(date))"
        }
        return trimmed
    }

    /// Renames a recording. Whitespace is trimmed; empty titles are ignored.
    func rename(_ recording: Recording, to title: String) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        recording.title = trimmed
        commit(recording)
    }

    /// Adds a tag. Whitespace is trimmed; empty and duplicate tags
    /// (case-insensitive) are ignored.
    func addTag(_ tag: String, to recording: Recording) {
        let trimmed = tag.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let exists = recording.tags.contains { $0.caseInsensitiveCompare(trimmed) == .orderedSame }
        guard !exists else { return }
        recording.tags.append(trimmed)
        commit(recording)
    }

    /// Removes a tag by exact value; a tag that isn't present is a no-op.
    func removeTag(_ tag: String, from recording: Recording) {
        guard recording.tags.contains(tag) else { return }
        recording.tags.removeAll { $0 == tag }
        commit(recording)
    }

    /// Replaces the notes text. Unlike titles, notes may be cleared to empty.
    func setNotes(_ notes: String, for recording: Recording) {
        guard recording.notes != notes else { return }
        recording.notes = notes
        commit(recording)
    }

    /// Stamps a metadata edit, persists it, and queues the push. Anything
    /// that changes what the server should hold goes through here.
    private func commit(_ recording: Recording) {
        recording.updatedAt = .now
        recording.syncState = .local
        try? modelContext.save()
        schedulePush(recording)
    }

    /// Every distinct tag across `recordings`, first-use order preserved,
    /// deduplicated case-insensitively.
    static func allTags(in recordings: [Recording]) -> [String] {
        var seen = Set<String>()
        var result: [String] = []
        for tag in recordings.flatMap(\.tags) {
            let key = tag.lowercased()
            if seen.insert(key).inserted {
                result.append(tag)
            }
        }
        return result
    }

    /// Deletes the media file (tolerating one that is already missing),
    /// then the row, then the server copy.
    ///
    /// Local deletion wins: the row goes whether or not the backend can be
    /// reached. A failed remote delete leaves an orphaned blob and document
    /// rather than a recording the user thought they'd removed.
    func delete(_ recording: Recording) throws {
        let fileURL = url(for: recording)
        // Read what the remote delete needs *before* the row goes away.
        let id = recording.id
        let storagePath = recording.storagePath

        if FileManager.default.fileExists(atPath: fileURL.path) {
            try FileManager.default.removeItem(at: fileURL)
        }
        try? FileManager.default.removeItem(at: fileURL.appendingPathExtension("thumbnail.jpg"))
        modelContext.delete(recording)
        try modelContext.save()

        guard let sync, let auth else { return }
        Task {
            guard let uid = await auth.currentUID() else { return }
            try? await sync.deleteRemote(id: id, storagePath: storagePath, uid: uid)
        }
    }

    // MARK: - Sync

    /// Pushes every recording the server is behind on. Called at launch so a
    /// session that ended offline catches up, and to retry past failures.
    func syncPending() async {
        guard sync != nil else { return }
        let descriptor = FetchDescriptor<Recording>(
            predicate: #Predicate { $0.syncStateRaw != "synced" },
            sortBy: [SortDescriptor(\.createdAt)]
        )
        guard let pending = try? modelContext.fetch(descriptor) else { return }
        for recording in pending {
            await push(recording)
        }
    }

    private func schedulePush(_ recording: Recording) {
        guard sync != nil else { return }
        Task { await push(recording) }
    }

    /// Uploads the blob if the server hasn't got it, then writes metadata.
    ///
    /// Failures are recorded on the row and otherwise swallowed: backup is a
    /// background courtesy, and the recording is safe on disk either way.
    private func push(_ recording: Recording) async {
        guard let sync, let auth else { return }

        let id = recording.id
        guard !inFlight.contains(id) else { return }
        inFlight.insert(id)
        defer { inFlight.remove(id) }

        guard let uid = await auth.currentUID() else {
            markFailed(recording)
            return
        }

        // An edit landing mid-push bumps `updatedAt`, which means the copy we
        // just sent is already stale. Loop until what we sent matches what's
        // on disk, so a save during a slow upload isn't stranded until the
        // next launch.
        while !recording.isDeleted {
            recording.syncState = .uploading
            try? modelContext.save()

            let snapshot = RecordingSnapshot(recording)
            let fileURL = url(for: recording)

            do {
                let storagePath: String
                if let known = recording.storagePath {
                    storagePath = known
                } else {
                    storagePath = try await sync.uploadMedia(snapshot, from: fileURL, uid: uid)
                }
                try await sync.pushMetadata(snapshot, storagePath: storagePath, uid: uid)

                guard !recording.isDeleted else { return }
                recording.storagePath = storagePath
                guard recording.updatedAt == snapshot.updatedAt else { continue }

                recording.syncState = .synced
                try? modelContext.save()
                return
            } catch {
                markFailed(recording)
                return
            }
        }
    }

    private func markFailed(_ recording: Recording) {
        guard !recording.isDeleted else { return }
        recording.syncState = .failed
        try? modelContext.save()
    }
}

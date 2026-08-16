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

    /// - Parameters:
    ///   - modelContext: The SwiftData context to insert/delete rows in.
    ///   - directory: Where media files live. Defaults to
    ///     `Application Support/Recordings`, created on init.
    init(modelContext: ModelContext, directory: URL? = nil) {
        self.modelContext = modelContext
        self.directory = directory
            ?? URL.applicationSupportDirectory.appending(path: "Recordings", directoryHint: .isDirectory)
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
        try modelContext.save()
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
        try? modelContext.save()
    }

    /// Adds a tag. Whitespace is trimmed; empty and duplicate tags
    /// (case-insensitive) are ignored.
    func addTag(_ tag: String, to recording: Recording) {
        let trimmed = tag.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let exists = recording.tags.contains { $0.caseInsensitiveCompare(trimmed) == .orderedSame }
        guard !exists else { return }
        recording.tags.append(trimmed)
        try? modelContext.save()
    }

    /// Removes a tag by exact value; a tag that isn't present is a no-op.
    func removeTag(_ tag: String, from recording: Recording) {
        recording.tags.removeAll { $0 == tag }
        try? modelContext.save()
    }

    /// Replaces the notes text. Unlike titles, notes may be cleared to empty.
    func setNotes(_ notes: String, for recording: Recording) {
        recording.notes = notes
        try? modelContext.save()
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
    /// then the row.
    func delete(_ recording: Recording) throws {
        let fileURL = url(for: recording)
        if FileManager.default.fileExists(atPath: fileURL.path) {
            try FileManager.default.removeItem(at: fileURL)
        }
        modelContext.delete(recording)
        try modelContext.save()
    }
}

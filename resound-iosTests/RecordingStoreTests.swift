import Foundation
import SwiftData
import Testing
import UniformTypeIdentifiers
@testable import resound_ios

@MainActor
struct RecordingStoreTests {
    /// In-memory SwiftData container plus a fresh temp media directory per test.
    private func makeStore() throws -> (store: RecordingStore, context: ModelContext, directory: URL) {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: Recording.self, configurations: configuration)
        let context = ModelContext(container)
        let directory = FileManager.default.temporaryDirectory
            .appending(path: "RecordingStoreTests-\(UUID().uuidString)", directoryHint: .isDirectory)
        let store = RecordingStore(modelContext: context, directory: directory)
        return (store, context, directory)
    }

    private func makeFixture(named name: String, bytes: Int = 2048) throws -> URL {
        let url = FileManager.default.temporaryDirectory.appending(path: name, directoryHint: .notDirectory)
        try Data(repeating: 0x2A, count: bytes).write(to: url)
        return url
    }

    private func rowCount(in context: ModelContext) throws -> Int {
        try context.fetchCount(FetchDescriptor<Recording>())
    }

    // MARK: - create

    @Test func createCopiesFileAndSetsSizeAndRelativeFileName() throws {
        let (store, context, directory) = try makeStore()
        let source = try makeFixture(named: "source-\(UUID().uuidString).mp4", bytes: 2048)
        defer { try? FileManager.default.removeItem(at: source) }

        let recording = try store.create(
            copying: source,
            kind: .video,
            title: "Handout",
            contentType: .mpeg4Movie,
            duration: nil
        )

        #expect(recording.size == 2048)
        #expect(recording.title == "Handout")
        #expect(recording.contentType == UTType.mpeg4Movie.identifier)
        // No auth/sync injected, so the row stays local and nothing is pushed.
        #expect(recording.syncState == .local)
        #expect(recording.storagePath == nil)

        // fileName is relative — "<uuid>.<ext>", no path separators.
        #expect(!recording.fileName.contains("/"))
        #expect(recording.fileName == "\(recording.id.uuidString).mp4")

        // The copy landed in the store's directory, source untouched.
        let copied = directory.appending(path: recording.fileName)
        #expect(FileManager.default.fileExists(atPath: copied.path))
        #expect(FileManager.default.fileExists(atPath: source.path))
        #expect(try rowCount(in: context) == 1)
    }

    // MARK: - importFile

    @Test func importVideoFileDerivesKindAndTitle() async throws {
        let (store, _, _) = try makeStore()
        let source = try makeFixture(named: "Lesson Take 3.mp4")
        defer { try? FileManager.default.removeItem(at: source) }

        let recording = try await store.importFile(at: source)

        #expect(recording.kind == .video)
        #expect(recording.title == "Lesson Take 3")
        #expect(recording.size == 2048)
        // Dummy bytes are not a decodable asset — no duration assertion
        // beyond it not being a bogus value.
        if let duration = recording.duration {
            #expect(duration >= 0)
        }
    }

    @Test func importCameraFilenameGetsDatedTitle() async throws {
        let (store, _, _) = try makeStore()
        let source = try makeFixture(named: "IMG_1234.mp4")
        defer { try? FileManager.default.removeItem(at: source) }

        let recording = try await store.importFile(at: source)

        #expect(recording.title == "Import — \(Format.shortDate(.now))")
    }

    // MARK: - importTitle rule

    @Test(arguments: [
        "IMG_1234", "img_1234", "VID-0042", "DSC 8871", "PXL_0007", "MOV_12", "IMG9999", "",
    ])
    func importTitleReplacesCameraStyleNames(_ name: String) {
        let date = Date(timeIntervalSince1970: 1_722_600_000)
        #expect(RecordingStore.importTitle(from: name, date: date) == "Import — \(Format.shortDate(date))")
    }

    @Test(arguments: [
        "Lesson Take 3", "IMG_1234 vacation", "Recital IMG_1234", "Sonata no. 2", "IMG_12a",
    ])
    func importTitleKeepsHumanNames(_ name: String) {
        #expect(RecordingStore.importTitle(from: name) == name)
    }

    @Test func importTitleTrimsWhitespace() {
        #expect(RecordingStore.importTitle(from: "  Scales practice  ") == "Scales practice")
    }

    // MARK: - rename

    @Test func renameTrimsWhitespace() throws {
        let (store, _, _) = try makeStore()
        let source = try makeFixture(named: "rename-\(UUID().uuidString).mp4")
        defer { try? FileManager.default.removeItem(at: source) }
        let recording = try store.create(copying: source, kind: .video, title: "Old", contentType: .mpeg4Movie, duration: nil)

        store.rename(recording, to: "  New title  ")

        #expect(recording.title == "New title")
    }

    @Test func renameIgnoresEmptyTitles() throws {
        let (store, _, _) = try makeStore()
        let source = try makeFixture(named: "rename-empty-\(UUID().uuidString).mp4")
        defer { try? FileManager.default.removeItem(at: source) }
        let recording = try store.create(copying: source, kind: .video, title: "Keep me", contentType: .mpeg4Movie, duration: nil)

        store.rename(recording, to: "   \n ")

        #expect(recording.title == "Keep me")
    }

    // MARK: - tags

    @Test func addTagTrimsAndAppends() throws {
        let (store, _, _) = try makeStore()
        let source = try makeFixture(named: "tags-\(UUID().uuidString).mp4")
        defer { try? FileManager.default.removeItem(at: source) }
        let recording = try store.create(copying: source, kind: .video, title: "T", contentType: .mpeg4Movie, duration: nil)

        store.addTag("  Scales ", to: recording)
        store.addTag("Jazz", to: recording)

        #expect(recording.tags == ["Scales", "Jazz"])
    }

    @Test func addTagIgnoresEmptyAndCaseInsensitiveDuplicates() throws {
        let (store, _, _) = try makeStore()
        let source = try makeFixture(named: "tags-dup-\(UUID().uuidString).mp4")
        defer { try? FileManager.default.removeItem(at: source) }
        let recording = try store.create(copying: source, kind: .video, title: "T", contentType: .mpeg4Movie, duration: nil)

        store.addTag("Scales", to: recording)
        store.addTag("scales", to: recording)
        store.addTag("   ", to: recording)

        #expect(recording.tags == ["Scales"])
    }

    @Test func removeTagRemovesExactMatchOnly() throws {
        let (store, _, _) = try makeStore()
        let source = try makeFixture(named: "tags-rm-\(UUID().uuidString).mp4")
        defer { try? FileManager.default.removeItem(at: source) }
        let recording = try store.create(copying: source, kind: .video, title: "T", contentType: .mpeg4Movie, duration: nil)
        store.addTag("Scales", to: recording)
        store.addTag("Jazz", to: recording)

        store.removeTag("Scales", from: recording)
        store.removeTag("Not there", from: recording)

        #expect(recording.tags == ["Jazz"])
    }

    @Test func allTagsDeduplicatesAcrossRecordingsPreservingOrder() {
        let a = Recording(kind: .video, title: "A", contentType: "t", size: 1, fileName: "a.mp4", tags: ["Scales", "Jazz"])
        let b = Recording(kind: .video, title: "B", contentType: "t", size: 1, fileName: "b.mp4", tags: ["jazz", "Improv"])

        #expect(RecordingStore.allTags(in: [a, b]) == ["Scales", "Jazz", "Improv"])
    }

    // MARK: - delete

    @Test func deleteRemovesFileAndRow() throws {
        let (store, context, _) = try makeStore()
        let source = try makeFixture(named: "delete-\(UUID().uuidString).mp4")
        defer { try? FileManager.default.removeItem(at: source) }
        let recording = try store.create(copying: source, kind: .video, title: "Doomed", contentType: .mpeg4Movie, duration: nil)
        let fileURL = store.url(for: recording)
        #expect(FileManager.default.fileExists(atPath: fileURL.path))

        try store.delete(recording)

        #expect(!FileManager.default.fileExists(atPath: fileURL.path))
        #expect(try rowCount(in: context) == 0)
    }

    @Test func deleteToleratesAlreadyMissingFile() throws {
        let (store, context, _) = try makeStore()
        let source = try makeFixture(named: "delete-missing-\(UUID().uuidString).mp4")
        defer { try? FileManager.default.removeItem(at: source) }
        let recording = try store.create(copying: source, kind: .video, title: "Ghost", contentType: .mpeg4Movie, duration: nil)
        try FileManager.default.removeItem(at: store.url(for: recording))

        try store.delete(recording)

        #expect(try rowCount(in: context) == 0)
    }

    // MARK: - url(for:)

    @Test func urlForRecordingIsDirectoryPlusFileName() throws {
        let (store, _, directory) = try makeStore()
        let recording = Recording(
            kind: .video,
            title: "Somewhere",
            contentType: UTType.mpeg4Movie.identifier,
            size: 1,
            fileName: "abc.mp4"
        )

        let expected = directory.appending(path: "abc.mp4", directoryHint: .notDirectory)
        #expect(store.url(for: recording).standardizedFileURL.path == expected.standardizedFileURL.path)
    }
}

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
        let source = try makeFixture(named: "source-\(UUID().uuidString).pdf", bytes: 2048)
        defer { try? FileManager.default.removeItem(at: source) }

        let recording = try store.create(
            copying: source,
            kind: .file,
            title: "Handout",
            contentType: .pdf,
            duration: nil
        )

        #expect(recording.size == 2048)
        #expect(recording.title == "Handout")
        #expect(recording.contentType == UTType.pdf.identifier)
        #expect(recording.syncState == "local")

        // fileName is relative — "<uuid>.<ext>", no path separators.
        #expect(!recording.fileName.contains("/"))
        #expect(recording.fileName == "\(recording.id.uuidString).pdf")

        // The copy landed in the store's directory, source untouched.
        let copied = directory.appending(path: recording.fileName)
        #expect(FileManager.default.fileExists(atPath: copied.path))
        #expect(FileManager.default.fileExists(atPath: source.path))
        #expect(try rowCount(in: context) == 1)
    }

    // MARK: - importFile

    @Test func importAudioFileDerivesKindAndTitle() async throws {
        let (store, _, _) = try makeStore()
        let source = try makeFixture(named: "Lesson Take 3.m4a")
        defer { try? FileManager.default.removeItem(at: source) }

        let recording = try await store.importFile(at: source)

        #expect(recording.kind == .audio)
        #expect(recording.title == "Lesson Take 3")
        #expect(recording.size == 2048)
        // Dummy bytes are not a decodable asset — no duration assertion
        // beyond it not being a bogus value.
        if let duration = recording.duration {
            #expect(duration >= 0)
        }
    }

    @Test func importPDFDerivesFileKindAndNilDuration() async throws {
        let (store, _, _) = try makeStore()
        let source = try makeFixture(named: "Sheet Music.pdf")
        defer { try? FileManager.default.removeItem(at: source) }

        let recording = try await store.importFile(at: source)

        #expect(recording.kind == .file)
        #expect(recording.title == "Sheet Music")
        #expect(recording.contentType == UTType.pdf.identifier)
        #expect(recording.duration == nil)
    }

    @Test func importCameraFilenameGetsDatedTitle() async throws {
        let (store, _, _) = try makeStore()
        let source = try makeFixture(named: "IMG_1234.jpg")
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
        let source = try makeFixture(named: "rename-\(UUID().uuidString).pdf")
        defer { try? FileManager.default.removeItem(at: source) }
        let recording = try store.create(copying: source, kind: .file, title: "Old", contentType: .pdf, duration: nil)

        store.rename(recording, to: "  New title  ")

        #expect(recording.title == "New title")
    }

    @Test func renameIgnoresEmptyTitles() throws {
        let (store, _, _) = try makeStore()
        let source = try makeFixture(named: "rename-empty-\(UUID().uuidString).pdf")
        defer { try? FileManager.default.removeItem(at: source) }
        let recording = try store.create(copying: source, kind: .file, title: "Keep me", contentType: .pdf, duration: nil)

        store.rename(recording, to: "   \n ")

        #expect(recording.title == "Keep me")
    }

    // MARK: - delete

    @Test func deleteRemovesFileAndRow() throws {
        let (store, context, _) = try makeStore()
        let source = try makeFixture(named: "delete-\(UUID().uuidString).pdf")
        defer { try? FileManager.default.removeItem(at: source) }
        let recording = try store.create(copying: source, kind: .file, title: "Doomed", contentType: .pdf, duration: nil)
        let fileURL = store.url(for: recording)
        #expect(FileManager.default.fileExists(atPath: fileURL.path))

        try store.delete(recording)

        #expect(!FileManager.default.fileExists(atPath: fileURL.path))
        #expect(try rowCount(in: context) == 0)
    }

    @Test func deleteToleratesAlreadyMissingFile() throws {
        let (store, context, _) = try makeStore()
        let source = try makeFixture(named: "delete-missing-\(UUID().uuidString).pdf")
        defer { try? FileManager.default.removeItem(at: source) }
        let recording = try store.create(copying: source, kind: .file, title: "Ghost", contentType: .pdf, duration: nil)
        try FileManager.default.removeItem(at: store.url(for: recording))

        try store.delete(recording)

        #expect(try rowCount(in: context) == 0)
    }

    // MARK: - url(for:)

    @Test func urlForRecordingIsDirectoryPlusFileName() throws {
        let (store, _, directory) = try makeStore()
        let recording = Recording(
            kind: .audio,
            title: "Somewhere",
            contentType: UTType.mpeg4Audio.identifier,
            size: 1,
            fileName: "abc.m4a"
        )

        let expected = directory.appending(path: "abc.m4a", directoryHint: .notDirectory)
        #expect(store.url(for: recording).standardizedFileURL.path == expected.standardizedFileURL.path)
    }
}

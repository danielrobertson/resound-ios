import AVFoundation
import PhotosUI
import SwiftUI
import UniformTypeIdentifiers

/// Media picked from the photo library, received as a copy in a private
/// temp directory (the system deletes its own copy when the closure
/// returns, so we must move it somewhere we own).
struct PickedMedia: Transferable {
    let url: URL

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(importedContentType: .movie) { received in
            PickedMedia(url: try copyToOwnedTemp(received.file))
        }
        FileRepresentation(importedContentType: .audio) { received in
            PickedMedia(url: try copyToOwnedTemp(received.file))
        }
        FileRepresentation(importedContentType: .image) { received in
            PickedMedia(url: try copyToOwnedTemp(received.file))
        }
    }

    private static func copyToOwnedTemp(_ file: URL) throws -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appending(path: UUID().uuidString, directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let destination = directory.appending(
            path: file.lastPathComponent,
            directoryHint: .notDirectory
        )
        try FileManager.default.copyItem(at: file, to: destination)
        return destination
    }
}

/// Wires both import paths — the Files document picker and the photo
/// library — into one modifier that funnels everything through
/// `RecordingStore.importFile(at:)`, with a progress overlay while the
/// copy runs and an alert on failure.
private struct MediaImport: ViewModifier {
    @Environment(RecordingStore.self) private var store

    @Binding var isVideoCaptureRequested: Bool
    @State private var isCameraPresented = false
    @Binding var isFileImporterPresented: Bool
    @Binding var isPhotosPickerPresented: Bool

    @State private var photoItem: PhotosPickerItem?
    @State private var isImporting = false
    @State private var errorMessage: String?

    func body(content: Content) -> some View {
        content
            .onChange(of: isVideoCaptureRequested) { _, requested in
                guard requested else { return }
                isVideoCaptureRequested = false
                Task { await openCamera() }
            }
            .fullScreenCover(isPresented: $isCameraPresented) {
                VideoCaptureView { result in
                    isCameraPresented = false
                    guard let result else { return }
                    switch result {
                    case .success(let url):
                        Task {
                            defer { try? FileManager.default.removeItem(at: url) }
                            await importFile(at: url)
                        }
                    case .failure:
                        errorMessage = "The video couldn't be saved. Try recording it again."
                    }
                }
                .ignoresSafeArea()
            }
            .fileImporter(
                isPresented: $isFileImporterPresented,
                allowedContentTypes: [.audio, .movie, .image, .pdf]
            ) { result in
                switch result {
                case .success(let url):
                    Task { await importFile(at: url) }
                case .failure:
                    errorMessage = "That file couldn't be opened."
                }
            }
            .photosPicker(
                isPresented: $isPhotosPickerPresented,
                selection: $photoItem,
                matching: .any(of: [.images, .videos])
            )
            .onChange(of: photoItem) { _, item in
                guard let item else { return }
                photoItem = nil
                Task { await importPhoto(item) }
            }
            .overlay {
                if isImporting {
                    ImportingOverlay()
                        .transition(.opacity)
                }
            }
            .animation(.settle, value: isImporting)
            .alert("Couldn’t add media", isPresented: isErrorPresented) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "That file couldn't be added to your studio.")
            }
    }

    @MainActor
    private func openCamera() async {
        guard UIImagePickerController.isSourceTypeAvailable(.camera),
              UIImagePickerController.availableMediaTypes(for: .camera)?.contains(UTType.movie.identifier) == true else {
            errorMessage = "This device has no video camera. Import a video from Photos instead."
            return
        }
        let camera = await AVCaptureDevice.requestAccess(for: .video)
        guard camera else {
            errorMessage = "Allow camera access in Settings to record video."
            return
        }
        let microphone = await AVCaptureDevice.requestAccess(for: .audio)
        guard microphone else {
            errorMessage = "Allow microphone access in Settings to record video with sound."
            return
        }
        isCameraPresented = true
    }

    private var isErrorPresented: Binding<Bool> {
        Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )
    }

    @MainActor
    private func importFile(at url: URL) async {
        isImporting = true
        defer { isImporting = false }
        do {
            try await store.importFile(at: url)
        } catch {
            errorMessage = "That file couldn't be added to your studio."
        }
    }

    @MainActor
    private func importPhoto(_ item: PhotosPickerItem) async {
        isImporting = true
        defer { isImporting = false }
        do {
            guard let media = try await item.loadTransferable(type: PickedMedia.self) else {
                errorMessage = "That item couldn't be loaded from your library."
                return
            }
            defer {
                try? FileManager.default.removeItem(at: media.url.deletingLastPathComponent())
            }
            try await store.importFile(at: media.url)
        } catch {
            errorMessage = "That item couldn't be added to your studio."
        }
    }
}

/// Dimmed scrim with a small card while an import copies media in.
private struct ImportingOverlay: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.2)
                .ignoresSafeArea()
            VStack(spacing: 12) {
                ProgressView()
                Text("Importing…")
                    .font(.body(14, .medium, relativeTo: .subheadline))
                    .foregroundStyle(Color.appForeground)
            }
            .padding(28)
            .background(
                RoundedRectangle(cornerRadius: Radius.xl2, style: .continuous)
                    .fill(Color.appCard)
            )
        }
    }
}

extension View {
    /// Attaches the Files importer, the photo picker, the importing
    /// overlay, and the failure alert. Toggle either binding to present
    /// the matching picker.
    func mediaImport(
        isVideoCaptureRequested: Binding<Bool>,
        isFileImporterPresented: Binding<Bool>,
        isPhotosPickerPresented: Binding<Bool>
    ) -> some View {
        modifier(MediaImport(
            isVideoCaptureRequested: isVideoCaptureRequested,
            isFileImporterPresented: isFileImporterPresented,
            isPhotosPickerPresented: isPhotosPickerPresented
        ))
    }
}

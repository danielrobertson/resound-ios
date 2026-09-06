import AVFoundation
import SwiftUI
import UniformTypeIdentifiers

/// Uses the system camera's recording, preview, retake, and acceptance UI.
struct VideoCaptureView: UIViewControllerRepresentable {
    let onFinish: (Result<URL, Error>?) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.mediaTypes = [UTType.movie.identifier]
        picker.cameraCaptureMode = .video
        picker.videoQuality = .typeHigh
        picker.videoMaximumDuration = 180
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ controller: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(onFinish: onFinish) }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let onFinish: (Result<URL, Error>?) -> Void
        init(onFinish: @escaping (Result<URL, Error>?) -> Void) { self.onFinish = onFinish }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) { onFinish(nil) }

        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            guard let source = info[.mediaURL] as? URL else {
                onFinish(.failure(CocoaError(.fileReadUnknown)))
                return
            }
            // Own the file before dismissing the picker, which owns its temporary URL.
            let destination = FileManager.default.temporaryDirectory
                .appendingPathComponent("VID-\(Int(Date.now.timeIntervalSince1970 * 1000)).\(source.pathExtension)")
            do {
                try FileManager.default.copyItem(at: source, to: destination)
                onFinish(.success(destination))
            } catch { onFinish(.failure(error)) }
        }
    }
}

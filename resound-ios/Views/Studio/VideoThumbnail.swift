import AVFoundation
import SwiftUI

struct VideoThumbnail: View {
    let url: URL
    @State private var thumbnail: UIImage?

    var body: some View {
        ZStack {
            Color.appMuted
            if let thumbnail {
                Image(uiImage: thumbnail)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: "video")
                    .foregroundStyle(Color.appMutedForeground)
            }
        }
        .frame(width: 64, height: 64)
        .clipped()
        .overlay(alignment: .bottomTrailing) {
            Image(systemName: "play.fill")
                .font(.system(size: 9))
                .foregroundStyle(.white)
                .padding(5)
                .background(.black.opacity(0.6), in: Circle())
                .padding(4)
        }
        .clipShape(RoundedRectangle(cornerRadius: Radius.xl))
        .accessibilityHidden(true)
        .task(id: url) {
            thumbnail = nil
            let cache = url.appendingPathExtension("thumbnail.jpg")
            if let image = UIImage(contentsOfFile: cache.path) {
                thumbnail = image
                return
            }
            let generator = AVAssetImageGenerator(asset: AVURLAsset(url: url))
            generator.appliesPreferredTrackTransform = true
            generator.maximumSize = CGSize(width: 240, height: 240)
            do {
                let result = try await generator.image(at: .zero)
                try Task.checkCancellation()
                let image = UIImage(cgImage: result.image)
                thumbnail = image
                // Do not recreate a cache after its recording was deleted.
                if FileManager.default.fileExists(atPath: url.path) {
                    try? image.jpegData(compressionQuality: 0.8)?.write(to: cache, options: .atomic)
                }
            } catch {
                // Keep the video symbol when a frame cannot be decoded.
            }
        }
    }
}

import AVFoundation
import SwiftUI

struct VideoThumbnail: View {
    let url: URL
    @State private var thumbnail: UIImage?

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.appSage
                if let thumbnail {
                    Image(uiImage: thumbnail)
                        .resizable()
                        .scaledToFill()
                } else {
                    HeroIcon(.video)
                        .foregroundStyle(Color.appMutedForeground)
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .clipped()
        }
        .accessibilityHidden(true)
        .task(id: url) {
            thumbnail = nil
            let cache = url.appendingPathExtension("grid-thumbnail.jpg")
            if let image = UIImage(contentsOfFile: cache.path) {
                thumbnail = image
                return
            }
            let generator = AVAssetImageGenerator(asset: AVURLAsset(url: url))
            generator.appliesPreferredTrackTransform = true
            generator.maximumSize = CGSize(width: 600, height: 800)
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

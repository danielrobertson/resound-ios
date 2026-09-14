import SwiftUI
import UniformTypeIdentifiers

/// A quiet library row with media preview, metadata, tags, and sync status.
struct RecordingCard: View {
    @Environment(RecordingStore.self) private var store
    let recording: Recording
    @State private var textTitle: String?

    var body: some View {
        Group {
            HStack(spacing: 14) {
                if recording.kind == .video {
                    VideoThumbnail(url: store.url(for: recording))
                } else {
                    HeroIcon(recording.kind.icon, size: 19)
                        .foregroundStyle(Color.appForeground.opacity(0.7))
                        .frame(width: 64, height: 64)
                        .background(
                            RoundedRectangle(cornerRadius: Radius.xl, style: .continuous)
                                .fill(Color.appMuted)
                        )

                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(textTitle ?? recording.title)
                        .font(.system(.subheadline, weight: .medium))
                        .foregroundStyle(Color.appForeground)
                        .lineLimit(1)
                    Text(Format.shortDate(recording.createdAt))
                        .font(.caption)
                        .foregroundStyle(Color.appMutedForeground)

                    if !recording.tags.isEmpty {
                        tagLine
                            .padding(.top, 3)
                    }
                }

                Spacer(minLength: 0)

                SyncBadge(state: recording.syncState)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 12)
        }
        .task(id: recording.updatedAt) {
            guard recording.isPlainText else { return }
            if let text = try? String(contentsOf: store.url(for: recording), encoding: .utf8) {
                textTitle = RecordingStore.textTitle(text)
            }
        }
    }

    /// Up to three tag capsules; the rest collapse into "+n".
    private var tagLine: some View {
        HStack(spacing: 5) {
            ForEach(recording.tags.prefix(3), id: \.self) { tag in
                Text(tag)
                    .font(.body(10, .medium, relativeTo: .caption2))
                    .foregroundStyle(Color.appForeground.opacity(0.7))
                    .lineLimit(1)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(Color.appMuted))
                    .overlay(Capsule().strokeBorder(Color.appBorder.opacity(0.7)))
            }
            if recording.tags.count > 3 {
                Text("+\(recording.tags.count - 3)")
                    .font(.body(10, .medium, relativeTo: .caption2))
                    .foregroundStyle(Color.appMutedForeground)
            }
        }
    }
}

extension RecordingKind {
    /// Heroicon for each recording kind.
    var icon: HeroIconName {
        switch self {
        case .audio: .audio
        case .video: .video
        case .file: .document
        }
    }
}

extension Recording {
    /// "Audio · 412 KB · Aug 3" — mirrors the web card's meta line.
    var metaLine: String {
        "\(UTType(contentType)?.conforms(to: .plainText) == true ? "Text" : kind.rawValue.capitalized) · \(Format.size(size)) · \(Format.shortDate(createdAt))"
    }
}

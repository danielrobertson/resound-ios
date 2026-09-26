import SwiftUI
import UniformTypeIdentifiers

/// A quiet library row with media preview, metadata, tags, and sync status.
struct RecordingCard: View {
    @Environment(RecordingStore.self) private var store
    let recording: Recording

    var body: some View {
        Group {
            HStack(spacing: 14) {
                VideoThumbnail(url: store.url(for: recording))

                VStack(alignment: .leading, spacing: 3) {
                    Text(recording.title)
                        .font(.body(16, .semibold, relativeTo: .headline))
                        .foregroundStyle(Color.appForeground)
                        .lineLimit(2)
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
            .padding(14)
            .appSurface(radius: 28)
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

            }
            if recording.tags.count > 3 {
                Text("+\(recording.tags.count - 3)")
                    .font(.body(10, .medium, relativeTo: .caption2))
                    .foregroundStyle(Color.appMutedForeground)
            }
        }
    }
}

extension Recording {
    var metaLine: String {
        "Video · \(Format.size(size)) · \(Format.shortDate(createdAt))"
    }
}

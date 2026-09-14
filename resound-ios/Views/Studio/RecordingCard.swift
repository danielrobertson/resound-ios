import SwiftUI

/// One row in the studio list — the web's `RecordingCard` translated into a
/// horizontal double-bezel card: kind icon in a muted square, title, and the
/// "Kind · size · date" meta line.
struct RecordingCard: View {
    @Environment(RecordingStore.self) private var store
    let recording: Recording

    var body: some View {
        DoubleBezel(outerRadius: 24, padding: 6, innerPadding: 20) {
            HStack(spacing: 14) {
                if recording.kind == .video {
                    VideoThumbnail(url: store.url(for: recording))
                } else {
                    HeroIcon(recording.kind.icon, size: 19)
                        .foregroundStyle(Color.appForeground.opacity(0.7))
                        .frame(width: 40, height: 40)
                        .background(
                            RoundedRectangle(cornerRadius: Radius.xl, style: .continuous)
                                .fill(Color.appMuted)
                        )

                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(recording.title)
                        .font(.body(15, .semibold, relativeTo: .subheadline))
                        .foregroundStyle(Color.appForeground)
                        .lineLimit(1)
                    Text(recording.metaLine)
                        .font(.body(12, relativeTo: .caption))
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
        "\(kind.rawValue.capitalized) · \(Format.size(size)) · \(Format.shortDate(createdAt))"
    }
}

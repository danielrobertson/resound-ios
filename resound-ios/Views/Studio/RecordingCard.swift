import SwiftUI

/// One row in the studio list — the web's `RecordingCard` translated into a
/// horizontal double-bezel card: kind icon in a muted square, title, and the
/// "Kind · size · date" meta line.
struct RecordingCard: View {
    let recording: Recording

    var body: some View {
        DoubleBezel(outerRadius: 24, padding: 6, innerPadding: 20) {
            HStack(spacing: 14) {
                Image(systemName: recording.kind.symbolName)
                    .font(.system(size: 19, weight: .light))
                    .foregroundStyle(Color.appForeground.opacity(0.7))
                    .frame(width: 40, height: 40)
                    .background(
                        RoundedRectangle(cornerRadius: Radius.xl, style: .continuous)
                            .fill(Color.appMuted)
                    )

                VStack(alignment: .leading, spacing: 3) {
                    Text(recording.title)
                        .font(.body(15, .semibold, relativeTo: .subheadline))
                        .foregroundStyle(Color.appForeground)
                        .lineLimit(1)
                    Text(recording.metaLine)
                        .font(.body(12, relativeTo: .caption))
                        .foregroundStyle(Color.appMutedForeground)
                }

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

extension RecordingKind {
    /// SF Symbol per kind, matching the web's Phosphor choices
    /// (WaveSine / VideoCamera / File) at light weight.
    var symbolName: String {
        switch self {
        case .audio: "waveform"
        case .video: "video"
        case .file: "doc.text"
        }
    }
}

extension Recording {
    /// "Audio · 412 KB · Aug 3" — mirrors the web card's meta line.
    var metaLine: String {
        "\(kind.rawValue.capitalized) · \(Format.size(size)) · \(Format.shortDate(createdAt))"
    }
}

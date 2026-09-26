import SwiftUI

/// A portrait video tile with an optional title over the thumbnail.
struct RecordingCard: View {
    @Environment(RecordingStore.self) private var store
    let recording: Recording

    private var title: String {
        recording.title.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        Color.appSage
            .aspectRatio(3.0 / 4.0, contentMode: .fit)
            .overlay {
                VideoThumbnail(url: store.url(for: recording))
            }
            .overlay(alignment: .bottomLeading) {
                if !title.isEmpty {
                    Text(title)
                        .font(.body(12, .semibold, relativeTo: .caption))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .shadow(color: .black.opacity(0.35), radius: 2, y: 1)
                        .padding(.horizontal, 8)
                        .padding(.bottom, 8)
                        .padding(.top, 28)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background {
                            LinearGradient(
                                colors: [.clear, .black.opacity(0.65)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        }
                }
            }
            .clipped()
            .contentShape(Rectangle())
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(title.isEmpty ? "Untitled video" : title)
            .accessibilityValue(Format.shortDate(recording.createdAt))
    }
}

extension Recording {
    var metaLine: String {
        "Video · \(Format.size(size)) · \(Format.shortDate(createdAt))"
    }
}

import SwiftData
import SwiftUI

/// Lesson media library, presented inside the app shell's Library tab.
struct StudioView: View {
    @Query(sort: \Recording.createdAt, order: .reverse)
    private var recordings: [Recording]

    @State private var selectedTag: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    header
                        .riseIn()

                    if recordings.isEmpty {
                        EmptyStateView()
                            .frame(maxWidth: .infinity)
                            .padding(.top, 140)
                    } else {
                        if !allTags.isEmpty {
                            tagFilter
                                .padding(.top, 24)
                        }
                        recordingList
                            .padding(.top, allTags.isEmpty ? 32 : 20)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)
                .padding(.bottom, 48)
            }
            .background { StudioBackground() }
            .navigationDestination(for: Recording.self) { recording in
                if recording.isPlainText {
                    LessonTextView(recording: recording)
                } else {
                    RecordingDetailView(recording: recording)
                }
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        Text("Library")
            .font(.system(.largeTitle, weight: .medium))
            .tracking(-0.8)
            .foregroundStyle(.primary)
    }

    // MARK: - Tag filter

    private var allTags: [String] {
        RecordingStore.allTags(in: recordings)
    }

    /// Recordings narrowed to the selected tag (case-insensitive); a selected
    /// tag whose last recording was deleted or untagged shows everything again.
    private var filteredRecordings: [Recording] {
        guard let selectedTag else { return recordings }
        return recordings.filter { recording in
            recording.tags.contains { $0.caseInsensitiveCompare(selectedTag) == .orderedSame }
        }
    }

    private var tagFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(allTags, id: \.self) { tag in
                    let isSelected = selectedTag?.caseInsensitiveCompare(tag) == .orderedSame
                    Button {
                        withAnimation(.settle) {
                            selectedTag = isSelected ? nil : tag
                        }
                    } label: {
                        Text(tag)
                            .font(.body(12, .medium, relativeTo: .caption))
                            .foregroundStyle(
                                isSelected ? Color.appPrimaryForeground : Color.appForeground.opacity(0.8)
                            )
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Capsule().fill(isSelected ? Color.appPrimary : Color.appMuted))
                            .overlay(Capsule().strokeBorder(Color.appBorder.opacity(isSelected ? 0 : 0.7)))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - List

    private var recordingList: some View {
        LazyVStack(spacing: 14) {
            ForEach(Array(filteredRecordings.enumerated()), id: \.element.id) { index, recording in
                NavigationLink(value: recording) {
                    RecordingCard(recording: recording)
                }
                .buttonStyle(.plain)
                .riseIn(delay: 0.08 + 0.08 * Double(min(index, 8)))
            }
        }
    }

}

import SwiftData
import SwiftUI

/// Lesson media library, presented inside the app shell's Library tab.
struct StudioView: View {
    @Query(filter: #Predicate<Recording> { $0.kindRaw == "video" }, sort: \Recording.createdAt, order: .reverse)
    private var recordings: [Recording]

    @Namespace private var videoTransition
    @State private var selectedTag: String?
    @State private var selectedRecording: Recording?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        header
                            .padding(.horizontal, 20)
                            .riseIn()

                        if recordings.isEmpty {
                            EmptyStateView()
                                .padding(.horizontal, 20)
                                .frame(maxWidth: .infinity)
                                .padding(.top, 56)
                        } else {
                            if !allTags.isEmpty {
                                tagFilter
                                    .padding(.horizontal, 20)
                                    .padding(.top, 24)
                            }
                            recordingGrid
                                .padding(.top, allTags.isEmpty ? 32 : 20)
                        }
                    }
                    .padding(.top, 24)
                    .padding(.bottom, 48)
                }
                .background { StudioBackground() }
                .onChange(of: allTags) { _, tags in
                    if let selectedTag, !tags.contains(where: { $0.caseInsensitiveCompare(selectedTag) == .orderedSame }) {
                        self.selectedTag = nil
                    }
                }
                .fullScreenCover(item: $selectedRecording) { recording in
                    RecordingViewer(
                        recordings: filteredRecordings,
                        selectedRecording: recording,
                        transitionNamespace: videoTransition,
                        onSelectionChanged: { id in proxy.scrollTo(id, anchor: .center) }
                    )
                }
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Library")
                    .font(.display(36, .semibold, relativeTo: .largeTitle))
                    .tracking(-0.8)
                    .foregroundStyle(Color.appForeground)
                if !recordings.isEmpty {
                    Text("\(recordings.count) \(recordings.count == 1 ? "video" : "videos")")
                        .font(.body(14, relativeTo: .subheadline))
                        .foregroundStyle(Color.appMutedForeground)
                }
            }
            Spacer()
            WaveMark()
                .stroke(Color.appForeground, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                .frame(width: 23, height: 23)
                .frame(width: 46, height: 46)
                .background(Color.appCard.opacity(0.75), in: Circle())
                .accessibilityHidden(true)
        }
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
                        withAnimation(reduceMotion ? nil : .settle) {
                            selectedTag = isSelected ? nil : tag
                        }
                    } label: {
                        Text(tag)
                            .font(.body(12, .medium, relativeTo: .caption))
                            .foregroundStyle(
                                isSelected ? Color.appPrimaryForeground : Color.appForeground.opacity(0.8)
                            )
                            .padding(.horizontal, 12)
                            .frame(minHeight: 44)
                            .background(Capsule().fill(isSelected ? Color.appPrimary : Color.appMuted))
                            .overlay(Capsule().strokeBorder(Color.appBorder.opacity(isSelected ? 0 : 0.7)))
                    }
                    .buttonStyle(AppPressStyle())
                    .accessibilityAddTraits(isSelected ? .isSelected : [])
                }
            }
        }
    }

    // MARK: - Grid

    private var recordingGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 1), count: 3), spacing: 1) {
            ForEach(Array(filteredRecordings.enumerated()), id: \.element.id) { index, recording in
                Button { selectedRecording = recording } label: {
                    RecordingCard(recording: recording)
                        .matchedTransitionSource(id: recording.id, in: videoTransition)
                }
                .id(recording.id)
                .buttonStyle(.plain)
                .riseIn(delay: 0.08 + 0.08 * Double(min(index, 8)))
            }
        }
    }

}

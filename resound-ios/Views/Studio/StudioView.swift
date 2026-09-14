import SwiftData
import SwiftUI

/// Lesson media library with a persistent, video-first creation dock.
struct StudioView: View {
    @Query(sort: \Recording.createdAt, order: .reverse)
    private var recordings: [Recording]

    @State private var isVideoCaptureRequested = false
    @State private var isRecordPresented = false
    @State private var isSettingsPresented = false
    @State private var isFileImporterPresented = false
    @State private var isPhotosPickerPresented = false
    @State private var isTextPresented = false
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
            .safeAreaInset(edge: .bottom, spacing: 0) { captureDock }
            .navigationDestination(for: Recording.self) { recording in
                if recording.isPlainText {
                    LessonTextView(recording: recording)
                } else {
                    RecordingDetailView(recording: recording)
                }
            }
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    settingsButton
                }
            }
            .fullScreenCover(isPresented: $isRecordPresented) {
                RecordView()
            }
            .sheet(isPresented: $isTextPresented) {
                LessonTextView()
            }
            .sheet(isPresented: $isSettingsPresented) {
                SettingsView()
            }
            .mediaImport(
                isVideoCaptureRequested: $isVideoCaptureRequested,
                isFileImporterPresented: $isFileImporterPresented,
                isPhotosPickerPresented: $isPhotosPickerPresented
            )
            .onAppear {
                #if DEBUG
                // Debug-only hook so tooling/screenshot runs can jump
                // straight into the record flow.
                if ProcessInfo.processInfo.arguments.contains("-autoRecord") {
                    isRecordPresented = true
                }
                #endif
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

    private var captureDock: some View {
        HStack(spacing: 12) {
            addMenu
                .frame(width: 44, height: 44)
                .background(Color(uiColor: .tertiarySystemFill), in: Circle())
            Spacer()
            Button {
                isRecordPresented = true
            } label: {
                HeroIcon(.microphone, size: 22)
                    .frame(width: 52, height: 52)
                    .background(Color(uiColor: .tertiarySystemFill), in: Circle())
            }
            .accessibilityLabel("Record audio")
            Button {
                isVideoCaptureRequested = true
            } label: {
                HeroIcon(.video, size: 24)
                    .foregroundStyle(.white)
                    .frame(width: 58, height: 58)
                    .background(Color(red: 0.204, green: 0.231, blue: 1), in: Circle())
            }
            .accessibilityLabel("Record video")
        }
        .buttonStyle(.plain)
        .foregroundStyle(.primary)
        .padding(10)
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 27))
        .overlay(RoundedRectangle(cornerRadius: 27).strokeBorder(.primary.opacity(0.04)))
        .shadow(color: .black.opacity(0.08), radius: 16, y: 6)
        .padding(.horizontal, 14)
        .padding(.bottom, 8)
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

    // MARK: - Toolbar

    private var addMenu: some View {
        Menu {
            Button {
                isTextPresented = true
            } label: {
                Label("Write text", image: HeroIconName.write.rawValue)
            }
            Button {
                isFileImporterPresented = true
            } label: {
                Label("Import from Files", image: HeroIconName.folder.rawValue)
            }
            Button {
                isPhotosPickerPresented = true
            } label: {
                Label("Import from Photos", image: HeroIconName.photo.rawValue)
            }
        } label: {
            HeroIcon(.plus, size: 22)
                .frame(width: 44, height: 44)
        }
        .accessibilityLabel("More creation options")
    }

    private var settingsButton: some View {
        Button {
            isSettingsPresented = true
        } label: {
            HeroIcon(.settings)
        }
        .accessibilityLabel("Settings")
    }
}

import AVKit
import SwiftUI

/// Detail for one recording: audio gets the 56-bar scrubbable waveform,
/// video a player, everything else a QuickLook preview. Toolbar carries
/// share, rename, and delete.
struct RecordingDetailView: View {
    @Environment(RecordingStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    let recording: Recording

    @State private var playback = PlaybackService()
    @State private var samples: [Float]?
    @State private var isRenamePresented = false
    @State private var newTitle = ""
    @State private var isDeletePresented = false
    @State private var newTag = ""
    @State private var notesDraft = ""
    @State private var notesSaveTask: Task<Void, Never>?
    @FocusState private var isNotesFocused: Bool

    private var fileURL: URL {
        store.url(for: recording)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(recording.title)
                        .font(.display(26, .semibold, relativeTo: .title))
                        .foregroundStyle(Color.appForeground)
                    Text(recording.metaLine)
                        .font(.body(13, relativeTo: .footnote))
                        .foregroundStyle(Color.appMutedForeground)
                }
                .riseIn()

                mediaSection
                    .riseIn(delay: 0.08)

                tagsSection
                    .riseIn(delay: 0.16)

                notesSection
                    .riseIn(delay: 0.24)
            }
            .padding(20)
        }
        .background(Color.appBackground)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                ShareLink(item: fileURL) {
                    Image(systemName: "square.and.arrow.up")
                        .fontWeight(.light)
                }
                .accessibilityLabel("Share")

                Button {
                    newTitle = recording.title
                    isRenamePresented = true
                } label: {
                    Image(systemName: "pencil")
                        .fontWeight(.light)
                }
                .accessibilityLabel("Rename")

                Button(role: .destructive) {
                    isDeletePresented = true
                } label: {
                    Image(systemName: "trash")
                        .fontWeight(.light)
                }
                .accessibilityLabel("Delete")
            }
        }
        .alert("Rename", isPresented: $isRenamePresented) {
            TextField("Title", text: $newTitle)
            Button("Save") {
                store.rename(recording, to: newTitle)
            }
            Button("Cancel", role: .cancel) {}
        }
        .confirmationDialog(
            "Delete this recording?",
            isPresented: $isDeletePresented,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                playback.stop()
                try? store.delete(recording)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("It will be removed from your studio permanently.")
        }
        .task {
            notesDraft = recording.notes
            if recording.kind == .audio || recording.kind == .video {
                await playback.load(url: fileURL)
            }
            if recording.kind == .audio {
                samples = try? await WaveformSampler.samples(from: fileURL)
            }
        }
        .onDisappear {
            playback.stop()
            notesSaveTask?.cancel()
            store.setNotes(notesDraft, for: recording)
        }
    }

    // MARK: - Tags

    private var tagsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("Tags")

            if !recording.tags.isEmpty {
                FlowLayout(spacing: 8) {
                    ForEach(recording.tags, id: \.self) { tag in
                        TagChip(tag: tag) {
                            withAnimation(.settle) {
                                store.removeTag(tag, from: recording)
                            }
                        }
                    }
                }
            }

            HStack(spacing: 8) {
                Image(systemName: "tag")
                    .font(.system(size: 13, weight: .light))
                    .foregroundStyle(Color.appMutedForeground)
                TextField("Add a tag", text: $newTag)
                    .font(.body(14, relativeTo: .subheadline))
                    .textInputAutocapitalization(.words)
                    .submitLabel(.done)
                    .onSubmit(commitTag)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: Radius.xl, style: .continuous)
                    .fill(Color.appMuted.opacity(0.5))
            )
            .overlay(
                RoundedRectangle(cornerRadius: Radius.xl, style: .continuous)
                    .strokeBorder(Color.appBorder.opacity(0.6))
            )
        }
    }

    private func commitTag() {
        withAnimation(.settle) {
            store.addTag(newTag, to: recording)
        }
        newTag = ""
    }

    // MARK: - Notes

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("Notes")

            TextEditor(text: $notesDraft)
                .font(.body(15, relativeTo: .body))
                .foregroundStyle(Color.appForeground)
                .scrollContentBackground(.hidden)
                .focused($isNotesFocused)
                .frame(minHeight: 120)
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: Radius.xl, style: .continuous)
                        .fill(Color.appMuted.opacity(0.5))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.xl, style: .continuous)
                        .strokeBorder(Color.appBorder.opacity(0.6))
                )
                .overlay(alignment: .topLeading) {
                    if notesDraft.isEmpty && !isNotesFocused {
                        Text("Main takeaways, things to practice…")
                            .font(.body(15, relativeTo: .body))
                            .foregroundStyle(Color.appMutedForeground.opacity(0.7))
                            .padding(.top, 18)
                            .padding(.leading, 15)
                            .allowsHitTesting(false)
                    }
                }
                .onChange(of: notesDraft) {
                    scheduleNotesSave()
                }
        }
    }

    /// Debounces persistence so we don't hit SwiftData on every keystroke;
    /// `onDisappear` flushes whatever is pending.
    private func scheduleNotesSave() {
        notesSaveTask?.cancel()
        notesSaveTask = Task {
            try? await Task.sleep(for: .seconds(1))
            guard !Task.isCancelled else { return }
            store.setNotes(notesDraft, for: recording)
        }
    }

    private func sectionLabel(_ title: String) -> some View {
        Text(title)
            .font(.body(10, .semibold, relativeTo: .caption2))
            .textCase(.uppercase)
            .tracking(2)
            .foregroundStyle(Color.appMutedForeground)
    }

    // MARK: - Media

    @ViewBuilder
    private var mediaSection: some View {
        switch recording.kind {
        case .audio:
            audioPlayer
        case .video:
            VideoPlayer(player: playback.player)
                .aspectRatio(16 / 9, contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: Radius.xl3, style: .continuous))
        case .file:
            QuickLookPreview(url: fileURL)
                .frame(height: 460)
                .clipShape(RoundedRectangle(cornerRadius: Radius.xl3, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.xl3, style: .continuous)
                        .strokeBorder(Color.appBorder.opacity(0.6), lineWidth: 1)
                )
        }
    }

    private var audioPlayer: some View {
        DoubleBezel(innerPadding: 24) {
            VStack(spacing: 24) {
                StaticWaveformView(
                    samples: samples ?? WaveformSampler.placeholder,
                    progress: playback.progress
                ) { fraction in
                    playback.seek(to: fraction * playbackDuration)
                }
                .frame(height: 88)
                .opacity(samples == nil ? 0.35 : 1)
                .animation(.settle, value: samples == nil)

                HStack(spacing: 16) {
                    Button {
                        playback.togglePlay()
                    } label: {
                        Image(systemName: playback.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(Color.appPrimaryForeground)
                            .frame(width: 52, height: 52)
                            .background(Circle().fill(Color.appPrimary))
                            .contentTransition(.symbolEffect(.replace))
                    }
                    .accessibilityLabel(playback.isPlaying ? "Pause" : "Play")

                    Text("\(Format.duration(playback.currentTime)) / \(Format.duration(playbackDuration))")
                        .font(.body(14, .medium, relativeTo: .subheadline))
                        .monospacedDigit()
                        .foregroundStyle(Color.appMutedForeground)

                    Spacer(minLength: 0)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    /// The player's duration once loaded, falling back to the stored value.
    private var playbackDuration: TimeInterval {
        playback.duration > 0 ? playback.duration : (recording.duration ?? 0)
    }
}

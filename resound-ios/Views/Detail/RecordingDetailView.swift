import AVKit
import SwiftUI

/// Playback comes first; title edits are inline and metadata lives in a sheet.
struct RecordingDetailView: View {
    @Environment(RecordingStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    let recording: Recording

    @State private var playback = PlaybackService()
    @State private var samples: [Float]?
    @State private var titleDraft = ""
    @State private var isDetailsPresented = false
    @State private var isDeletePresented = false
    @State private var deletionError: String?
    @State private var wasDeleted = false
    @State private var isInitialized = false
    @State private var newTag = ""
    @State private var notesDraft = ""
    @State private var notesSaveTask: Task<Void, Never>?
    @FocusState private var isNotesFocused: Bool
    @FocusState private var isTitleFocused: Bool

    private var fileURL: URL { store.url(for: recording) }

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    mediaSection
                        .frame(minHeight: recording.kind == .audio ? geometry.size.height * 0.48 : nil)

                    VStack(alignment: .leading, spacing: 10) {
                        TextField("Title", text: $titleDraft, axis: .vertical)
                            .font(.system(.title, weight: .medium))
                            .tracking(-0.6)
                            .focused($isTitleFocused)
                            .submitLabel(.done)
                            .onSubmit { isTitleFocused = false }
                            .accessibilityLabel("Recording title")
                            .accessibilityHint("Tap to rename this recording")
                        Text(recording.createdAt.formatted(date: .abbreviated, time: .shortened))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Button { isDetailsPresented = true } label: {
                        HStack(spacing: 8) {
                            HeroIcon(.information)
                            Text("Notes & tags")
                            Spacer()
                            HeroIcon(.chevronRight, size: 12)
                        }
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(minHeight: 44)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 32)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .background { StudioBackground() }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if isTitleFocused {
                    Button("Done") { isTitleFocused = false }
                } else {
                    Menu {
                        Button { isDetailsPresented = true } label: {
                            Label("Edit notes & tags", image: HeroIconName.tag.rawValue)
                        }
                        ShareLink(item: fileURL) {
                            Label("Share", image: HeroIconName.share.rawValue)
                        }
                        Button(role: .destructive) { isDeletePresented = true } label: {
                            Label("Delete recording", image: HeroIconName.trash.rawValue)
                        }
                    } label: {
                        HeroIcon(.ellipsis)
                    }
                    .accessibilityLabel("Recording options")
                }
            }
        }
        .sheet(isPresented: $isDetailsPresented, onDismiss: saveDetails) {
            NavigationStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 28) {
                        Text(recording.metaLine)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        tagsSection
                        notesSection
                    }
                    .padding(20)
                }
                .background { StudioBackground() }
                .navigationTitle("Notes & tags")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") { isDetailsPresented = false }
                    }
                }
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .confirmationDialog("Delete this recording?", isPresented: $isDeletePresented, titleVisibility: .visible) {
            Button("Delete recording", role: .destructive) {
                do {
                    try store.delete(recording)
                    wasDeleted = true
                    notesSaveTask?.cancel()
                    playback.stop()
                    dismiss()
                } catch {
                    deletionError = error.localizedDescription
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("The recording and its notes will be permanently deleted.")
        }
        .alert("Couldn’t delete recording", isPresented: Binding(
            get: { deletionError != nil }, set: { if !$0 { deletionError = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(deletionError ?? "Try again.")
        }
        .task {
            if !isInitialized {
                titleDraft = recording.title
                notesDraft = recording.notes
                isInitialized = true
            }
            if recording.kind == .audio || recording.kind == .video {
                await playback.load(url: fileURL)
                guard !Task.isCancelled else { return }
                playback.play()
            }
        }
        .task {
            if recording.kind == .audio {
                samples = try? await WaveformSampler.samples(from: fileURL)
            }
        }
        .onChange(of: isTitleFocused) { _, focused in
            if !focused { saveTitle() }
        }
        .onDisappear {
            playback.stop()
            guard !wasDeleted, isInitialized else { return }
            saveTitle()
            saveDetails()
        }
    }

    private func saveTitle() {
        guard isInitialized, !wasDeleted else { return }
        if titleDraft.trimmingCharacters(in: .whitespacesAndNewlines) != recording.title {
            store.rename(recording, to: titleDraft)
        }
        titleDraft = recording.title
    }

    private func saveDetails() {
        guard isInitialized, !wasDeleted else { return }
        notesSaveTask?.cancel()
        if !newTag.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { commitTag() }
        store.setNotes(notesDraft, for: recording)
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
                HeroIcon(.tag, size: 13)
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
            .font(.subheadline.weight(.medium))
            .foregroundStyle(Color.appMutedForeground)
    }

    // MARK: - Media

    @ViewBuilder
    private var mediaSection: some View {
        if let error = playback.errorMessage {
            ContentUnavailableView {
                Label("Couldn’t play recording", image: HeroIconName.warning.rawValue)
            } description: {
                Text(error)
            } actions: {
                Button("Try again") {
                    Task {
                        await playback.load(url: fileURL)
                        guard !Task.isCancelled else { return }
                        playback.play()
                    }
                }
            }
        } else {
            switch recording.kind {
            case .audio:
                audioPlayer
            case .video:
                VideoPlayer(player: playback.player)
                    .frame(height: 380)
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            case .file:
                QuickLookPreview(url: fileURL)
                    .frame(height: 460)
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            }
        }
    }

    private var audioPlayer: some View {
        VStack(spacing: 28) {
            Spacer(minLength: 12)
            StaticWaveformView(
                samples: samples ?? WaveformSampler.placeholder,
                progress: playback.progress
            ) { fraction in
                playback.seek(to: fraction * playbackDuration)
            }
            .frame(height: 140)
            .opacity(samples == nil ? 0.35 : 1)
            .animation(.settle, value: samples == nil)

            HStack {
                Text(Format.duration(playback.currentTime))
                Spacer()
                Text(Format.duration(playbackDuration))
            }
            .font(.caption.monospacedDigit())
            .foregroundStyle(.secondary)

            HStack(spacing: 36) {
                skipButton(seconds: -15, icon: .backward, label: "Back 15 seconds")
                Button { playback.togglePlay() } label: {
                    HeroIcon(playback.isPlaying ? .pause : .play, size: 28)
                        .foregroundStyle(.white)
                        .frame(width: 80, height: 80)
                        .background(Color(red: 0.204, green: 0.231, blue: 1), in: Circle())
                        .contentTransition(.opacity)
                }
                .accessibilityLabel(playback.isPlaying ? "Pause" : "Play")
                skipButton(seconds: 15, icon: .forward, label: "Forward 15 seconds")
            }
            .buttonStyle(.plain)
            Spacer(minLength: 12)
        }
        .padding(.horizontal, 12)
    }

    private func skipButton(seconds: TimeInterval, icon: HeroIconName, label: String) -> some View {
        Button { playback.seek(to: playback.currentTime + seconds) } label: {
            VStack(spacing: 2) {
                HeroIcon(icon, size: 22)
                Text("15")
                    .font(.caption2.monospacedDigit().weight(.medium))
            }
                .foregroundStyle(.primary)
                .frame(width: 48, height: 48)
        }
        .accessibilityLabel(label)
    }

    /// The player's duration once loaded, falling back to the stored value.
    private var playbackDuration: TimeInterval {
        playback.duration > 0 ? playback.duration : (recording.duration ?? 0)
    }
}

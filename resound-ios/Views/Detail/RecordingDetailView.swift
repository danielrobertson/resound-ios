import AVKit
import SwiftUI

/// Playback comes first; title edits are inline and metadata lives in a sheet.
struct RecordingDetailView: View {
    @Environment(RecordingStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    let recording: Recording

    @State private var playback = PlaybackService()
    @State private var titleDraft = ""
    @State private var isDetailsPresented = false
    @State private var isDeletePresented = false
    @State private var deletionError: String?
    @State private var wasDeleted = false
    @State private var isInitialized = false
    @State private var newTag = ""
    @FocusState private var isTitleFocused: Bool

    private var fileURL: URL { store.url(for: recording) }

    var body: some View {
        Group {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    mediaSection

                    VStack(alignment: .leading, spacing: 10) {
                        TextField("Title", text: $titleDraft, axis: .vertical)
                            .font(.display(28, .semibold, relativeTo: .title))
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
                            Text("Tags")
                            Spacer()
                            HeroIcon(.chevronRight, size: 12)
                        }
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(minHeight: 44)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .appSurface(radius: Radius.xl2)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(AppPressStyle())
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
                            Label("Edit tags", image: HeroIconName.tag.rawValue)
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
                    }
                    .padding(20)
                }
                // Let the system sheet supply its adaptive iOS 26 material.
                .navigationTitle("Tags")
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
                    playback.stop()
                    dismiss()
                } catch {
                    deletionError = error.localizedDescription
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This video will be permanently deleted.")
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
                isInitialized = true
            }
            do {
                await playback.load(url: fileURL)
                guard !Task.isCancelled else { return }
                playback.play()
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
        if !newTag.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { commitTag() }
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
            VideoPlayer(player: playback.player)
                .frame(height: 380)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        }
    }
}

import AVKit
import SwiftUI

/// Vertical paging follows the Library order captured when opened.
struct RecordingViewer: View {
    @State private var recordings: [Recording]
    @State private var selectedID: UUID?
    @State private var dismissalOffset: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let transitionNamespace: Namespace.ID
    let onSelectionChanged: (UUID) -> Void
    private let initialID: UUID

    init(
        recordings: [Recording], selectedRecording: Recording,
        transitionNamespace: Namespace.ID, onSelectionChanged: @escaping (UUID) -> Void
    ) {
        self.transitionNamespace = transitionNamespace
        self.onSelectionChanged = onSelectionChanged
        initialID = selectedRecording.id
        _recordings = State(initialValue: recordings)
        _selectedID = State(initialValue: selectedRecording.id)
    }

    var body: some View {
        GeometryReader { geometry in
            ScrollView(.vertical) {
                LazyVStack(spacing: 0) {
                    ForEach(recordings) { recording in
                        RecordingDetailView(
                            recording: recording,
                            isActive: selectedID == recording.id,
                            onDismissalDrag: { dismissalOffset = $0 }
                        )
                            .padding(.top, geometry.safeAreaInsets.top)
                            .padding(.bottom, geometry.safeAreaInsets.bottom)
                            .containerRelativeFrame([.horizontal, .vertical])
                            .id(recording.id)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.paging)
            .scrollPosition(id: $selectedID)
            .scrollIndicators(.hidden)
            .scrollBounceBehavior(.basedOnSize)
            .ignoresSafeArea()
        }
        .background(.black)
        .scaleEffect(reduceMotion ? 1 : 1 - min(dismissalOffset / 1_200, 0.22))
        .offset(x: reduceMotion ? 0 : dismissalOffset * 0.6)
        .presentationBackground(.clear)
        .interactiveDismissDisabled()
        .navigationTransition(.zoom(sourceID: selectedID ?? initialID, in: transitionNamespace))
        .onChange(of: selectedID) { _, id in
            if let id { onSelectionChanged(id) }
        }
    }

}

/// Full-screen playback with editable details tucked into a sheet.
struct RecordingDetailView: View {
    @Environment(RecordingStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase

    let recording: Recording
    let isActive: Bool
    let onDismissalDrag: (CGFloat) -> Void

    @GestureState private var dismissalDrag: CGFloat = 0
    @State private var isDismissing = false
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
        ZStack {
            Color.black.ignoresSafeArea()
            mediaSection
                .ignoresSafeArea()
                .simultaneousGesture(dismissGesture)
        }
        .safeAreaInset(edge: .top) {
            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .frame(width: 44, height: 44)
                        .background(.black.opacity(0.4), in: Circle())
                }
                .accessibilityLabel("Close video")
                Spacer()
                Menu {
                    ShareLink(item: fileURL) {
                        Label("Share", image: HeroIconName.share.rawValue)
                    }
                    Button(role: .destructive) { isDeletePresented = true } label: {
                        Label("Delete recording", image: HeroIconName.trash.rawValue)
                    }
                } label: {
                    HeroIcon(.ellipsis)
                        .frame(width: 44, height: 44)
                        .background(.black.opacity(0.4), in: Circle())
                }
                .accessibilityLabel("Recording options")
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 12) {
                if playback.duration > 0 {
                    Slider(value: Binding(
                        get: { playback.currentTime },
                        set: { playback.seek(to: $0) }
                    ), in: 0...playback.duration)
                    .tint(.white)
                    .accessibilityLabel("Playback position")
                }
                Button { isDetailsPresented = true } label: {
                    HStack {
                        Text(titleDraft.isEmpty ? "Video details" : titleDraft)
                            .lineLimit(1)
                            .truncationMode(.tail)
                        Spacer()
                        Image(systemName: "chevron.up")
                    }
                    .font(.subheadline.weight(.semibold))
                    .frame(minHeight: 44)
                    .contentShape(Rectangle())
                }
                .accessibilityLabel("Show video details")
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 20)
            .padding(.bottom, 8)
            .background {
                LinearGradient(colors: [.clear, .black.opacity(0.7)], startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea(edges: .bottom)
            }
        }
        .background(.black)
        .sheet(isPresented: $isDetailsPresented, onDismiss: saveDetails) {
            NavigationStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 28) {
                        TextField("Title", text: $titleDraft, axis: .vertical)
                            .font(.title2.weight(.semibold))
                            .focused($isTitleFocused)
                            .accessibilityLabel("Recording title")
                        Text(recording.metaLine)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        if !recording.notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                sectionLabel("Notes")
                                Text(recording.notes)
                            }
                        }
                        tagsSection
                    }
                    .padding(20)
                }
                // Let the system sheet supply its adaptive iOS 26 material.
                .navigationTitle("Details")
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
        .task(id: isActive) {
            guard isActive else {
                playback.stop()
                return
            }
            if !isInitialized {
                titleDraft = recording.title
                isInitialized = true
            }
            do {
                await playback.load(url: fileURL)
                guard !Task.isCancelled, isActive, scenePhase == .active else { return }
                playback.play()
            }
        }
        .onChange(of: dismissalDrag) { _, offset in
            guard !isDismissing else { return }
            if offset == 0 {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                    onDismissalDrag(0)
                }
            } else {
                onDismissalDrag(offset)
            }
        }
        .onChange(of: isTitleFocused) { _, focused in
            if !focused { saveTitle() }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase != .active { playback.pause() }
        }
        .onChange(of: isDetailsPresented) { _, presented in
            if presented { playback.pause() }
        }
        .onDisappear {
            playback.stop()
            guard !wasDeleted, isInitialized else { return }
            saveTitle()
            saveDetails()
        }
    }

    /// A rightward drag can start anywhere on the video. Vertical drags stay
    /// with the pager; dragging the scrubber continues to seek the video.
    private var dismissGesture: some Gesture {
        DragGesture(minimumDistance: 20, coordinateSpace: .global)
            .updating($dismissalDrag) { value, offset, _ in
                let translation = value.translation
                offset = translation.width > 0 && translation.width > abs(translation.height) * 1.5
                    ? translation.width : 0
            }
            .onEnded { value in
                let translation = value.translation
                if translation.width > 0,
                   translation.width > abs(translation.height) * 1.5,
                   translation.width > 90 || value.predictedEndTranslation.width > 180 {
                    isDismissing = true
                    playback.stop()
                    dismiss()
                }
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
        saveTitle()
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
                        guard !Task.isCancelled, isActive, scenePhase == .active else { return }
                        playback.play()
                    }
                }
            }
        } else {
            Button {
                if playback.isPlaying { playback.pause() } else { playback.play() }
            } label: {
                PlayerSurface(player: playback.player)
                    .overlay {
                        if !playback.isPlaying {
                            Image(systemName: "play.fill")
                                .font(.system(size: 44))
                                .foregroundStyle(.white)
                                .shadow(radius: 8)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(playback.isPlaying ? "Pause video" : "Play video")
        }
    }
}

/// A video layer without native controls competing with the full-screen overlay.
private struct PlayerSurface: UIViewRepresentable {
    let player: AVPlayer

    func makeUIView(context: Context) -> PlayerUIView {
        let view = PlayerUIView()
        view.playerLayer.videoGravity = .resizeAspect
        view.playerLayer.player = player
        return view
    }

    func updateUIView(_ view: PlayerUIView, context: Context) {
        view.playerLayer.player = player
    }

    final class PlayerUIView: UIView {
        override class var layerClass: AnyClass { AVPlayerLayer.self }
        var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }
    }
}

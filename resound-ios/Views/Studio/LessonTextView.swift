import SwiftUI
import UniformTypeIdentifiers

/// Text uses the existing local file and sync pipeline, just like imported media.
struct LessonTextView: View {
    @Environment(RecordingStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    var recording: Recording? = nil
    @State private var isLoaded = false
    @State private var savedText = ""
    @State private var saveTask: Task<Void, Never>?
    @Environment(\.scenePhase) private var scenePhase
    @State private var text = ""
    @State private var errorMessage: String?
    @State private var isDiscardPresented = false
    @State private var isDeletePresented = false
    @State private var wasDeleted = false
    @FocusState private var editorFocused: Bool

    private var hasContent: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        Group {
            if recording == nil {
                NavigationStack { editor }
            } else {
                editor
            }
        }
        .interactiveDismissDisabled(recording == nil && !text.isEmpty)
    }

    private var editor: some View {
            VStack(alignment: .leading, spacing: 16) {
                ZStack(alignment: .topLeading) {
                    if text.isEmpty {
                        Text("What would you like to remember from this lesson?")
                            .foregroundStyle(.secondary)
                            .padding(.top, 8)
                            .padding(.leading, 5)
                            .allowsHitTesting(false)
                    }
                    TextEditor(text: $text)
                        .scrollContentBackground(.hidden)
                        .focused($editorFocused)
                        .accessibilityLabel("Lesson text")
                        .disabled(!isLoaded)
                        .font(.body)
                }
            }
            .padding(20)
            .background { StudioBackground() }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    if recording == nil { Button("Cancel") {
                        if !text.isEmpty { isDiscardPresented = true }
                        else { dismiss() }
                    } }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if recording == nil || editorFocused {
                        Button(recording == nil ? "Save" : "Done", action: save)
                            .disabled(recording == nil && !hasContent)
                    } else if let recording {
                        Menu {
                            ShareLink(item: store.url(for: recording)) {
                                Label("Share", image: HeroIconName.share.rawValue)
                            }
                            Button(role: .destructive) { isDeletePresented = true } label: {
                                Label("Delete text", image: HeroIconName.trash.rawValue)
                            }
                        } label: {
                            HeroIcon(.ellipsis)
                        }
                        .accessibilityLabel("Text options")
                    }
                }
            }
            .confirmationDialog("Delete this text?", isPresented: $isDeletePresented, titleVisibility: .visible) {
                Button("Delete text", role: .destructive) {
                    guard let recording else { return }
                    do {
                        try store.delete(recording)
                        wasDeleted = true
                        saveTask?.cancel()
                        dismiss()
                    } catch { errorMessage = error.localizedDescription }
                }
            } message: {
                Text("This text will be permanently deleted.")
            }
            .confirmationDialog("Discard this text?", isPresented: $isDiscardPresented, titleVisibility: .visible) {
                Button("Discard", role: .destructive) { dismiss() }
            }
            .alert("Couldn’t save text", isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("OK") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "Please try again.")
            }
            .onAppear {
                guard !isLoaded else { return }
                if let recording {
                    do {
                        text = try String(contentsOf: store.url(for: recording), encoding: .utf8)
                        savedText = text
                        isLoaded = true
                    } catch { errorMessage = error.localizedDescription }
                } else {
                    isLoaded = true
                    editorFocused = true
                }
            }
            .onChange(of: text) {
                guard recording != nil, isLoaded else { return }
                saveTask?.cancel()
                saveTask = Task {
                    try? await Task.sleep(for: .milliseconds(500))
                    guard !Task.isCancelled else { return }
                    persistText()
                }
            }
            .onChange(of: scenePhase) { _, phase in
                if phase != .active { persistText() }
            }
            .onDisappear {
                saveTask?.cancel()
                persistText()
            }
    }

    private func persistText() {
        guard let recording, !wasDeleted, isLoaded, text != savedText else { return }
        do {
            try store.setText(text, for: recording)
            savedText = text
        } catch { errorMessage = error.localizedDescription }
    }

    private func save() {
        if recording != nil {
            persistText()
            if errorMessage == nil { editorFocused = false }
            return
        }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension("txt")
        defer { try? FileManager.default.removeItem(at: url) }
        do {
            try text.write(to: url, atomically: true, encoding: .utf8)
            try store.create(copying: url, kind: .file,
                             title: RecordingStore.textTitle(text),
                             contentType: .utf8PlainText, duration: nil)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

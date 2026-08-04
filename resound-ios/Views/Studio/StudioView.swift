import SwiftData
import SwiftUI

/// The home screen — the user's studio. Mirrors the web app's `/studio`
/// route: eyebrow, display welcome, capture-count subtitle, and either the
/// empty-state action cards or the recording list.
struct StudioView: View {
    @Query(sort: \Recording.createdAt, order: .reverse)
    private var recordings: [Recording]

    @State private var isRecordPresented = false
    @State private var isSettingsPresented = false
    @State private var isFileImporterPresented = false
    @State private var isPhotosPickerPresented = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    header
                        .riseIn()

                    if recordings.isEmpty {
                        EmptyStateView(
                            onRecord: { isRecordPresented = true },
                            onUpload: { isFileImporterPresented = true }
                        )
                        .padding(.top, 40)
                    } else {
                        recordingList
                            .padding(.top, 32)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)
                .padding(.bottom, 48)
            }
            .background(Color.appBackground)
            .navigationDestination(for: Recording.self) { recording in
                RecordingDetailView(recording: recording)
            }
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    addMenu
                    settingsButton
                }
            }
            .fullScreenCover(isPresented: $isRecordPresented) {
                RecordView()
            }
            .sheet(isPresented: $isSettingsPresented) {
                SettingsView()
            }
            .mediaImport(
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
        VStack(alignment: .leading, spacing: 0) {
            Text("Your studio")
                .font(.body(10, .semibold, relativeTo: .caption2))
                .textCase(.uppercase)
                .tracking(2)
                .foregroundStyle(Color.appMutedForeground)
                .padding(.horizontal, 12)
                .padding(.vertical, 5)
                .overlay(Capsule().strokeBorder(Color.appBorder))

            Text("Welcome back.")
                .font(.display(30, .semibold, relativeTo: .largeTitle))
                .foregroundStyle(Color.appForeground)
                .padding(.top, 16)

            Text(subtitle)
                .font(.body(15, relativeTo: .subheadline))
                .foregroundStyle(Color.appMutedForeground)
                .padding(.top, 8)
        }
    }

    private var subtitle: String {
        if recordings.isEmpty {
            "Capture your first lesson moment — it will resonate here."
        } else {
            "\(recordings.count) lesson \(recordings.count == 1 ? "moment" : "moments") captured."
        }
    }

    // MARK: - List

    private var recordingList: some View {
        LazyVStack(spacing: 14) {
            ForEach(Array(recordings.enumerated()), id: \.element.id) { index, recording in
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
                isRecordPresented = true
            } label: {
                Label("Record audio", systemImage: "mic")
            }
            Button {
                isFileImporterPresented = true
            } label: {
                Label("Import from Files", systemImage: "folder")
            }
            Button {
                isPhotosPickerPresented = true
            } label: {
                Label("Import from Photos", systemImage: "photo.on.rectangle")
            }
        } label: {
            Image(systemName: "plus")
                .fontWeight(.light)
        }
        .accessibilityLabel("Add a lesson moment")
    }

    private var settingsButton: some View {
        Button {
            isSettingsPresented = true
        } label: {
            Image(systemName: "gearshape")
                .fontWeight(.light)
        }
        .accessibilityLabel("Settings")
    }
}

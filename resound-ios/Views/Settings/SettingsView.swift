import SwiftData
import SwiftUI

/// Appearance preference, backup status, plus the brand's About block.
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(RecordingStore.self) private var store
    @Environment(AuthService.self) private var auth
    @AppStorage(ThemePreference.storageKey) private var theme: ThemePreference = .system

    @Query private var recordings: [Recording]
    @State private var isRetrying = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Appearance") {
                    Picker("Appearance", selection: $theme) {
                        ForEach(ThemePreference.allCases) { preference in
                            Text(preference.label).tag(preference)
                        }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                }

                backupSection

                Section("About") {
                    VStack(spacing: 10) {
                        WaveMark()
                            .stroke(
                                Color.appPrimary,
                                style: StrokeStyle(lineWidth: 2.4, lineCap: .round)
                            )
                            .frame(width: 36, height: 36)
                            .accessibilityHidden(true)

                        Text("resound")
                            .font(.display(26, .semibold, relativeTo: .title2))
                            .foregroundStyle(Color.appForeground)

                        Text("Lessons that continue to resonate.")
                            .font(.body(13, relativeTo: .footnote))
                            .foregroundStyle(Color.appMutedForeground)

                        Text("Version \(appVersion)")
                            .font(.body(12, relativeTo: .caption))
                            .foregroundStyle(Color.appMutedForeground.opacity(0.7))
                            .padding(.top, 2)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    // MARK: - Backup

    private var pendingCount: Int {
        recordings.filter { $0.syncState != .synced }.count
    }

    private var failedCount: Int {
        recordings.filter { $0.syncState == .failed }.count
    }

    @ViewBuilder
    private var backupSection: some View {
        Section {
            LabeledContent("Status") {
                Text(statusText)
                    .foregroundStyle(failedCount > 0 ? Color.appDestructive : Color.appMutedForeground)
            }

            if pendingCount > 0 {
                Button {
                    isRetrying = true
                    Task {
                        await store.syncPending()
                        isRetrying = false
                    }
                } label: {
                    if isRetrying {
                        HStack(spacing: 8) {
                            ProgressView().controlSize(.mini)
                            Text("Backing up…")
                        }
                    } else {
                        Text("Back up now")
                    }
                }
                .disabled(isRetrying)
            }
        } header: {
            Text("Backup")
        } footer: {
            // Anonymous accounts are keychain-bound: there's no way to sign
            // back into one, so saying "backed up" without this caveat would
            // promise a recovery path that doesn't exist yet.
            Text("Recordings are copied to your private cloud vault. This device is signed in anonymously — deleting the app loses access to that vault, so keep the originals until accounts arrive.")
        }
    }

    private var statusText: String {
        if !auth.isSignedIn {
            return "Not connected"
        }
        if failedCount > 0 {
            return "\(failedCount) failed"
        }
        if pendingCount > 0 {
            return "\(pendingCount) waiting"
        }
        return recordings.isEmpty ? "Nothing to back up" : "All backed up"
    }

    private var appVersion: String {
        let short = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        if let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String {
            return "\(short) (\(build))"
        }
        return short
    }
}

#Preview("Settings") {
    let container = try! ModelContainer(
        for: Recording.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    // No sync service — the preview shows the local-only state.
    SettingsView()
        .environment(RecordingStore(modelContext: container.mainContext))
        .environment(AuthService())
        .modelContainer(container)
}

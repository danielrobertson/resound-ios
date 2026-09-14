import SwiftData
import SwiftUI

@main
struct resound_iosApp: App {
    @AppStorage(ThemePreference.storageKey) private var theme: ThemePreference = .system

    private let container: ModelContainer
    private let store: RecordingStore
    private let auth: AuthService

    init() {
        FirebaseBootstrap.configure()
        let auth = AuthService()
        self.auth = auth
        do {
            let container = try ModelContainer(for: Recording.self)
            self.container = container
            self.store = RecordingStore(
                modelContext: container.mainContext,
                auth: auth,
                sync: SyncService()
            )
        } catch {
            fatalError("Failed to create the model container: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            AppShellView()
                .environment(store)
                .environment(auth)
                .modelContainer(container)
                .preferredColorScheme(theme.colorScheme)
                .task {
                    // Sign in up front so the first save doesn't wait on it,
                    // then flush anything a previous offline session left.
                    await auth.currentUID()
                    await store.syncPending()
                }
        }
    }
}

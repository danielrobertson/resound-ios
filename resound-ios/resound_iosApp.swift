import SwiftData
import SwiftUI

@main
struct resound_iosApp: App {
    @AppStorage(ThemePreference.storageKey) private var theme: ThemePreference = .system

    private let container: ModelContainer
    private let store: RecordingStore

    init() {
        FirebaseBootstrap.configure()
        do {
            let container = try ModelContainer(for: Recording.self)
            self.container = container
            self.store = RecordingStore(modelContext: container.mainContext)
        } catch {
            fatalError("Failed to create the model container: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            StudioView()
                .environment(store)
                .modelContainer(container)
                .preferredColorScheme(theme.colorScheme)
        }
    }
}

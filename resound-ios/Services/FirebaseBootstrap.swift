import FirebaseAppCheck
import FirebaseCore
import Foundation

/// One-time Firebase startup. Safe to call when `GoogleService-Info.plist`
/// hasn't been added yet (e.g. fresh checkouts before Firebase setup): it
/// simply does nothing, and the app keeps working local-only.
enum FirebaseBootstrap {
    private(set) static var isConfigured = false

    static func configure() {
        guard !isConfigured else { return }
        guard Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil else {
            return
        }

        // App Check must be registered *before* FirebaseApp.configure().
        // App Attest in release; debug provider in debug builds so the
        // simulator can talk to protected backends.
        #if DEBUG
        AppCheck.setAppCheckProviderFactory(AppCheckDebugProviderFactory())
        #else
        AppCheck.setAppCheckProviderFactory(AppAttestProviderFactory())
        #endif

        FirebaseApp.configure()
        isConfigured = true
    }
}

/// App Attest provider for release builds, per Firebase's recommended setup.
private final class AppAttestProviderFactory: NSObject, AppCheckProviderFactory {
    func createProvider(with app: FirebaseApp) -> AppCheckProvider? {
        AppAttestProvider(app: app)
    }
}

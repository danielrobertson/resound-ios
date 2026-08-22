import FirebaseAuth
import Foundation
import Observation

/// The device's identity with the backend.
///
/// Every Firestore and Storage rule gates on `request.auth.uid`, so nothing
/// reaches the cloud until this resolves. Sign-in is anonymous: Firebase keeps
/// the credential in the keychain, so the same uid comes back on every launch.
///
/// The catch worth knowing: an anonymous uid does *not* survive deleting the
/// app, and there is no way to recover the vault it owned. Upgrading to a real
/// provider later means `link`ing credentials onto this account rather than
/// signing in fresh — that keeps the uid, and with it everything already
/// uploaded under it.
@MainActor
@Observable
final class AuthService {
    private(set) var uid: String?
    /// Last sign-in failure, for surfacing in settings. Cleared on success.
    private(set) var lastError: String?

    /// Shared by concurrent callers so a burst of saves triggers one sign-in
    /// rather than a race of several.
    @ObservationIgnored
    private var pending: Task<String?, Never>?

    var isSignedIn: Bool { uid != nil }

    /// The current uid, signing in anonymously on first call.
    ///
    /// Returns nil when Firebase isn't configured (a checkout without
    /// `GoogleService-Info.plist`) or when sign-in fails — callers treat that
    /// as "stay local" rather than an error worth interrupting the user for.
    @discardableResult
    func currentUID() async -> String? {
        guard FirebaseBootstrap.isConfigured else { return nil }

        if let uid { return uid }
        if let existing = Auth.auth().currentUser {
            uid = existing.uid
            return existing.uid
        }
        if let pending { return await pending.value }

        let task = Task { () -> String? in
            do {
                return try await Auth.auth().signInAnonymously().user.uid
            } catch {
                lastError = error.localizedDescription
                return nil
            }
        }
        pending = task
        let result = await task.value
        pending = nil

        uid = result
        if result != nil { lastError = nil }
        return result
    }
}

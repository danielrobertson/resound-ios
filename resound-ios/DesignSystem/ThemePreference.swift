import SwiftUI

/// User-selectable appearance override, persisted via
/// `@AppStorage(ThemePreference.storageKey)`.
enum ThemePreference: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    /// `@AppStorage` / `UserDefaults` key.
    static let storageKey = "themePreference"

    var id: String { rawValue }

    /// Value for `preferredColorScheme(_:)`; `nil` follows the system.
    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }

    var label: String {
        switch self {
        case .system: "System"
        case .light: "Light"
        case .dark: "Dark"
        }
    }
}

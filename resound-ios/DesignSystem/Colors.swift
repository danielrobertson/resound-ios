import SwiftUI

/// Semantic color tokens mirroring the web design system (`styles.css` OKLCH
/// variables, converted to sRGB). Each resolves an asset-catalog colorset with
/// light/dark appearance variants, so they compose with `preferredColorScheme`.
///
/// `appPrimary` and `appSecondary` are not declared here: their colorsets are
/// named "AppPrimary"/"AppSecondary" (renamed to avoid clashing with the
/// system's `Color.primary`/`.secondary` symbols), so Xcode's generated asset
/// symbols already provide `Color.appPrimary` and `Color.appSecondary`.
extension Color {
    static let appPrimaryForeground = Color("PrimaryForeground")
    static let appBackground = Color("Background")
    static let appForeground = Color("Foreground")
    static let appCard = Color("Card")
    static let appMuted = Color("Muted")
    static let appMutedForeground = Color("MutedForeground")
    static let appBorder = Color("Border")
    static let appDestructive = Color("Destructive")
}

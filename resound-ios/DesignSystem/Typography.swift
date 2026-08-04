import SwiftUI
import UIKit

/// PostScript/family names for the bundled variable fonts. Kept as single
/// constants so they are trivial to correct once WP0 reports the runtime
/// names from a `UIFont.familyNames` dump.
enum AppFontName {
    /// Web: `--font-sans: 'Inter Variable'`.
    static let body = "Inter"
    /// Web: `--font-heading: 'Bricolage Grotesque Variable'`.
    static let display = "Bricolage Grotesque"

    /// The Bricolage variable font's fvar default is 96pt ExtraBold, so the
    /// bare family name resolves to that face. Pin each weight to its named
    /// instance instead of relying on `.weight()` face re-selection.
    static func displayFace(for weight: Font.Weight) -> String {
        let suffix: String
        switch weight {
        case .ultraLight, .thin: suffix = "ExtraLight"
        case .light: suffix = "Light"
        case .regular: suffix = "Regular"
        case .medium: suffix = "Medium"
        case .semibold: suffix = "SemiBold"
        case .bold: suffix = "Bold"
        case .heavy, .black: suffix = "ExtraBold"
        default: suffix = "SemiBold"
        }
        return "BricolageGrotesque-96ptExtraBold_\(suffix)"
    }
}

extension Font {
    /// Body text font (Inter), scaling with Dynamic Type via `relativeTo`.
    /// Falls back to the system font if the custom font is not registered.
    static func body(
        _ size: CGFloat,
        _ weight: Font.Weight = .regular,
        relativeTo textStyle: Font.TextStyle = .body
    ) -> Font {
        appFont(named: AppFontName.body, size: size, weight: weight, relativeTo: textStyle)
    }

    /// Display/heading font (Bricolage Grotesque), used for titles only —
    /// mirrors the web's heading treatment.
    static func display(
        _ size: CGFloat,
        _ weight: Font.Weight = .semibold,
        relativeTo textStyle: Font.TextStyle = .title
    ) -> Font {
        let face = AppFontName.displayFace(for: weight)
        guard UIFont(name: face, size: size) != nil else {
            return .system(size: size, weight: weight, design: .default)
        }
        return Font.custom(face, size: size, relativeTo: textStyle)
    }

    private static func appFont(
        named name: String,
        size: CGFloat,
        weight: Font.Weight,
        relativeTo textStyle: Font.TextStyle
    ) -> Font {
        // The fonts are bundled by WP0; guard so a bad name degrades to SF
        // rather than rendering an unresolved custom font.
        guard UIFont(name: name, size: size) != nil else {
            return .system(size: size, weight: weight, design: .default)
        }
        return Font.custom(name, size: size, relativeTo: textStyle).weight(weight)
    }
}

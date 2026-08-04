import CoreGraphics

/// Corner radii derived from the web scale (`--radius: 0.625rem` = 10pt;
/// sm/md/lg/xl are ±4/±2/0/+4, 2xl–4xl are ×1.8/×2.2/×2.6).
enum Radius {
    static let sm: CGFloat = 6
    static let md: CGFloat = 8
    static let lg: CGFloat = 10
    static let xl: CGFloat = 14
    static let xl2: CGFloat = 18
    static let xl3: CGFloat = 22
    static let xl4: CGFloat = 26
    /// Outer shell of the double-bezel container (web `rounded-[1.75rem]`).
    static let bezelOuter: CGFloat = 28
}

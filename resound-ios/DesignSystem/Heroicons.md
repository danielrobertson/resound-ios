# Heroicons

App-owned icons use [Heroicons v2.2.0](https://github.com/tailwindlabs/heroicons/tree/v2.2.0), under the MIT license in `Resources/Heroicons-LICENSE.txt`.

Use `HeroIcon(.microphone, size: 24)` in views and `Label("Share", image: HeroIconName.share.rawValue)` in native menus. The view scales with Dynamic Type and inherits foreground styles. Keep accessibility labels on icon-only controls.

Assets are the official optimized 24px SVGs, with `currentColor` replaced by black for Xcode template rendering. Each imageset preserves vectors and uses template rendering. Navigation and actions use outline icons; play, pause, and stop use solid icons. System-owned controls such as back buttons and the video player keep the platform appearance.

To add an icon, copy its SVG from the pinned upstream version, apply the same color substitution, add a template imageset, and add a case to `HeroIconName`. No runtime dependency or network request is needed.

import SwiftUI

/// Locally bundled Heroicons v2.2.0. Raw values also work with native menu labels.
enum HeroIconName: String {
    case microphone = "hero-microphone-outline"
    case audio = "hero-musical-note-outline"
    case video = "hero-video-camera-outline"
    case document = "hero-document-text-outline"
    case information = "hero-information-circle-outline"
    case chevronRight = "hero-chevron-right-outline"
    case tag = "hero-tag-outline"
    case share = "hero-arrow-up-on-square-outline"
    case trash = "hero-trash-outline"
    case ellipsis = "hero-ellipsis-horizontal-outline"
    case warning = "hero-exclamation-circle-outline"
    case close = "hero-x-mark-outline"
    case play = "hero-play-solid"
    case pause = "hero-pause-solid"
    case stop = "hero-stop-solid"
    case unavailable = "hero-no-symbol-outline"
    case upload = "hero-arrow-up-tray-outline"
    case arrowUpRight = "hero-arrow-up-right-outline"
    case backup = "hero-cloud-arrow-up-outline"
    case plus = "hero-plus-outline"
    case settings = "hero-cog-6-tooth-outline"
    case write = "hero-pencil-square-outline"
    case folder = "hero-folder-outline"
    case photo = "hero-photo-outline"
    case backward = "hero-arrow-uturn-left-outline"
    case forward = "hero-arrow-uturn-right-outline"
}

/// Template vectors inherit foreground styles and scale with Dynamic Type.
struct HeroIcon: View {
    let name: HeroIconName
    @ScaledMetric private var size: CGFloat

    init(_ name: HeroIconName, size: CGFloat = 20) {
        self.name = name
        _size = ScaledMetric(wrappedValue: size, relativeTo: .body)
    }

    var body: some View {
        Image(name.rawValue)
            .renderingMode(.template)
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
    }
}

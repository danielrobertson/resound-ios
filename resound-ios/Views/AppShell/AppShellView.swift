import SwiftUI

/// Four durable destinations plus one creation action that stays available at
/// the app root. Capture does not take up a selected navigation destination.
struct AppShellView: View {
    enum Tab: CaseIterable {
        case review, library, find, you

        var title: String {
            switch self {
            case .review: "Review"
            case .library: "Library"
            case .find: "Find"
            case .you: "You"
            }
        }

        var icon: HeroIconName {
            switch self {
            case .review: .review
            case .library: .folder
            case .find: .tag
            case .you: .settings
            }
        }
    }

    @State private var selectedTab: Tab = .library
    @State private var isVideoCaptureRequested = false
    @State private var isFileImporterPresented = false
    @State private var isPhotosPickerPresented = false

    var body: some View {
        Group {
            switch selectedTab {
            case .review: ReviewPrototypeView()
            case .library: StudioView()
            case .find: FindPrototypeView()
            case .you: YouPrototypeView()
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            AppFooter(selectedTab: $selectedTab) { isVideoCaptureRequested = true }
        }
        .background(Color.appBackground)
        .foregroundStyle(Color.appForeground)
        .tint(Color.primary)
        .mediaImport(
            isVideoCaptureRequested: $isVideoCaptureRequested,
            isFileImporterPresented: $isFileImporterPresented,
            isPhotosPickerPresented: $isPhotosPickerPresented
        )
        .onAppear {
            #if DEBUG
            if ProcessInfo.processInfo.arguments.contains("-autoRecord") {
                isVideoCaptureRequested = true
            }
            #endif
        }
    }
}

private struct AppFooter: View {
    @Binding var selectedTab: AppShellView.Tab
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorScheme) private var colorScheme
    @Namespace private var selection
    @ScaledMetric(relativeTo: .caption2) private var itemHeight = 54.0
    let create: () -> Void

    var body: some View {
        GlassEffectContainer(spacing: 8) {
            HStack(spacing: 12) {
                navigationBar
                    .tint(Color.primary)

                Button(action: create) {
                    HeroIcon(.plus, size: 27)
                        .foregroundStyle(Color.appPrimaryForeground)
                        .frame(width: 32, height: 32)
                }
                .buttonStyle(.glassProminent)
                .buttonBorderShape(.circle)
                .controlSize(.large)
                .tint(Color.appPrimary)
                .accessibilityLabel("Record video")
                .accessibilityHint("Opens the device camera")
            }
        }
        .frame(maxWidth: 520)
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 8)
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private var navigationBar: some View {
        if reduceTransparency {
            tabItems
                .background(Color.appCard, in: Capsule())
                .overlay { Capsule().strokeBorder(Color.appBorder, lineWidth: 1) }
        } else {
            // iOS 26 supplies the refraction, edge highlights, and touch response.
            // Keep the material untinted so content can show through the navigation.
            tabItems
                .glassEffect(.regular.interactive(), in: Capsule())
        }
    }

    private var tabItems: some View {
        HStack(spacing: 0) {
            ForEach(AppShellView.Tab.allCases, id: \.self) { tab in
                tabButton(tab)
            }
        }
        .padding(5)
    }

    private func tabButton(_ tab: AppShellView.Tab) -> some View {
        Button {
            withAnimation(reduceMotion ? nil : .settle) { selectedTab = tab }
        } label: {
            VStack(spacing: 4) {
                HeroIcon(tab.icon, size: 21).frame(height: 24)
                Text(tab.title)
                    .font(.body(10, .semibold, relativeTo: .caption2))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .foregroundStyle(selectedTab == tab ? Color.primary : Color.secondary)
            .frame(maxWidth: .infinity, minHeight: itemHeight)
            .background {
                if selectedTab == tab {
                    Capsule()
                        .fill(colorScheme == .dark ? Color.white.opacity(0.16) : Color.black.opacity(0.07))
                        .matchedGeometryEffect(id: "selectedTab", in: selection)
                }
            }
            .contentShape(Capsule())
        }
        .buttonStyle(AppPressStyle())
        .accessibilityAddTraits(selectedTab == tab ? .isSelected : [])
    }
}

private struct ReviewPrototypeView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 7) {
                        Text("Review")
                            .font(.display(36, .semibold, relativeTo: .largeTitle))
                        Text("A short practice plan for today.")
                            .font(.body(16, relativeTo: .body))
                            .foregroundStyle(Color.appMutedForeground)
                    }
                    ReviewFocusCard()
                    VStack(alignment: .leading, spacing: 12) {
                        Text("From your last lesson")
                            .font(.body(16, .semibold, relativeTo: .headline))
                        ReviewRow(title: "Keep the shoulder quiet", source: "Warm-up · 0:42", icon: .video)
                        ReviewRow(title: "Try the phrase without pedal", source: "Nocturne in E-flat · 12:08", icon: .video)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)
                .padding(.bottom, 34)
            }
            .background { StudioBackground() }
        }
    }
}

private struct ReviewFocusCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("START HERE")
                    .font(.body(10, .semibold, relativeTo: .caption2))
                    .tracking(1.4)
                    .foregroundStyle(Color.appBrandTint)
                Spacer()
                HeroIcon(.video, size: 19).foregroundStyle(Color.appBrandTint)
            }
            Text("Let the note settle before you move on.")
                .font(.display(25, .semibold, relativeTo: .title2))
                .foregroundStyle(Color.appForeground)
            HStack(spacing: 10) {
                Button {} label: {
                    HStack(spacing: 8) {
                        HeroIcon(.play, size: 13)
                        Text("Play clip")
                    }
                    .font(.body(14, .medium, relativeTo: .subheadline))
                    .foregroundStyle(Color.appPrimaryForeground)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Capsule().fill(Color.appPrimary))
                }
                .buttonStyle(AppPressStyle())
                Text("Scales · 0:18")
                    .font(.body(13, relativeTo: .caption))
                    .foregroundStyle(Color.appMutedForeground)
            }
        }
        .padding(22)
        .background {
            RoundedRectangle(cornerRadius: Radius.xl4, style: .continuous)
                .fill(LinearGradient(colors: [Color.appSage, Color.appPeach],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
        }
    }
}

private struct ReviewRow: View {
    let title: String
    let source: String
    let icon: HeroIconName

    var body: some View {
        HStack(spacing: 13) {
            HeroIcon(icon, size: 18)
                .foregroundStyle(Color.appForeground.opacity(0.7))
                .frame(width: 42, height: 42)
                .background(RoundedRectangle(cornerRadius: Radius.xl, style: .continuous).fill(Color.appMuted))
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.body(15, .medium, relativeTo: .body))
                Text(source).font(.body(12, relativeTo: .caption)).foregroundStyle(Color.appMutedForeground)
            }
            Spacer()
            HeroIcon(.chevronRight, size: 16).foregroundStyle(Color.appMutedForeground)
        }
        .padding(16)
        .appSurface()
    }
}

private struct FindPrototypeView: View {
    private let themes = ["Tone", "Technique", "Rhythm", "Repertoire"]

    private func themeColor(_ theme: String) -> Color {
        switch theme {
        case "Tone": .appSage
        case "Technique": .appSky
        case "Rhythm": .appPeach
        default: .appMuted
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("Find")
                        .font(.display(36, .semibold, relativeTo: .largeTitle))
                    HStack(spacing: 10) {
                        HeroIcon(.tag, size: 19).foregroundStyle(Color.appMutedForeground)
                        Text("Search videos")
                            .font(.body(16, relativeTo: .body))
                            .foregroundStyle(Color.appMutedForeground)
                        Spacer()
                    }
                    .padding(.horizontal, 14)
                    .frame(height: 50)
                    .appSurface(radius: Radius.xl2)
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Browse by theme")
                            .font(.body(16, .semibold, relativeTo: .headline))
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                            ForEach(themes, id: \.self) { theme in
                                HStack {
                                    Text(theme).font(.body(15, .medium, relativeTo: .body))
                                    Spacer()
                                    HeroIcon(.chevronRight, size: 14)
                                }
                                .foregroundStyle(Color.appForeground)
                                .padding(15)
                                .background(themeColor(theme), in: RoundedRectangle(cornerRadius: Radius.xl2, style: .continuous))
                            }
                        }
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        Text("A useful search starts with a feeling")
                            .font(.body(16, .semibold, relativeTo: .headline))
                        Text("Try \"tight left hand\" or \"when the chorus rushes\". Resound brings back the lesson moment, not only a title.")
                            .font(.body(15, relativeTo: .body))
                            .foregroundStyle(Color.appMutedForeground)
                    }
                    .padding(18)
                    .background(RoundedRectangle(cornerRadius: Radius.xl2, style: .continuous).fill(Color.appMuted.opacity(0.72)))
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)
                .padding(.bottom, 34)
            }
            .background { StudioBackground() }
        }
    }
}

private struct YouPrototypeView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("You")
                        .font(.display(36, .semibold, relativeTo: .largeTitle))
                    VStack(alignment: .leading, spacing: 8) {
                        Text("This month's focus")
                            .font(.body(13, .medium, relativeTo: .subheadline))
                            .foregroundStyle(Color.appMutedForeground)
                        Text("Make the melody sing without rushing it.")
                            .font(.display(23, .semibold, relativeTo: .title2))
                        Text("Set after your Sep 10 lesson")
                            .font(.body(13, relativeTo: .caption))
                            .foregroundStyle(Color.appMutedForeground)
                    }
                    .padding(20)
                    .appSurface(radius: Radius.xl3)
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Your space")
                            .font(.body(16, .semibold, relativeTo: .headline))
                        NavigationLink { SettingsView() } label: {
                            ReviewRow(title: "Settings", source: "Account, appearance, and sync", icon: .settings)
                        }
                        .buttonStyle(.plain)
                        ReviewRow(title: "Teacher connections", source: "Share feedback when you choose", icon: .share)
                        ReviewRow(title: "Your practice history", source: "A record of what you returned to", icon: .document)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)
                .padding(.bottom, 34)
            }
            .background { StudioBackground() }
        }
    }
}

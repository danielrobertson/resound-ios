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
            case .review: .audio
            case .library: .folder
            case .find: .tag
            case .you: .settings
            }
        }
    }

    @State private var selectedTab: Tab = .review
    @State private var isCreatePresented = false
    @State private var isAudioRecordPresented = false
    @State private var isVideoCaptureRequested = false
    @State private var isFileImporterPresented = false
    @State private var isPhotosPickerPresented = false
    @State private var isTextPresented = false

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
            AppFooter(selectedTab: $selectedTab) { isCreatePresented = true }
        }
        .confirmationDialog("Add to Resound", isPresented: $isCreatePresented, titleVisibility: .visible) {
            Button { isAudioRecordPresented = true } label: {
                Label("Record audio", image: HeroIconName.microphone.rawValue)
            }
            Button { isVideoCaptureRequested = true } label: {
                Label("Record video", image: HeroIconName.video.rawValue)
            }
            Button { isTextPresented = true } label: {
                Label("Write a note", image: HeroIconName.write.rawValue)
            }
            Button { isFileImporterPresented = true } label: {
                Label("Import from Files", image: HeroIconName.folder.rawValue)
            }
            Button { isPhotosPickerPresented = true } label: {
                Label("Import from Photos", image: HeroIconName.photo.rawValue)
            }
        }
        .fullScreenCover(isPresented: $isAudioRecordPresented) { RecordView() }
        .sheet(isPresented: $isTextPresented) { LessonTextView() }
        .mediaImport(
            isVideoCaptureRequested: $isVideoCaptureRequested,
            isFileImporterPresented: $isFileImporterPresented,
            isPhotosPickerPresented: $isPhotosPickerPresented
        )
        .onAppear {
            #if DEBUG
            if ProcessInfo.processInfo.arguments.contains("-autoRecord") {
                isAudioRecordPresented = true
            }
            #endif
        }
    }
}

private struct AppFooter: View {
    @Binding var selectedTab: AppShellView.Tab
    let create: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            tabButton(.review)
            tabButton(.library)
            Spacer(minLength: 54)
            tabButton(.find)
            tabButton(.you)
        }
        .overlay(alignment: .top) {
            Button(action: create) {
                HeroIcon(.plus, size: 25)
                    .foregroundStyle(Color.appPrimaryForeground)
                    .frame(width: 58, height: 58)
                    .background(Circle().fill(Color.appPrimary))
                    .shadow(color: Color.appPrimary.opacity(0.3), radius: 12, y: 5)
            }
            .buttonStyle(FooterPressStyle())
            .accessibilityLabel("Add to Resound")
            .accessibilityHint("Records audio or video, imports media, or writes a note")
            .offset(y: -24)
        }
        .padding(.horizontal, 12)
        .padding(.top, 15)
        .padding(.bottom, 7)
        .background(.ultraThinMaterial)
        .overlay(alignment: .top) {
            Rectangle().fill(Color.appBorder.opacity(0.55)).frame(height: 0.5)
        }
    }

    private func tabButton(_ tab: AppShellView.Tab) -> some View {
        Button {
            withAnimation(.settle) { selectedTab = tab }
        } label: {
            VStack(spacing: 4) {
                HeroIcon(tab.icon, size: 21).frame(height: 24)
                Text(tab.title)
                    .font(.body(10, .medium, relativeTo: .caption2))
                    .lineLimit(1)
            }
            .foregroundStyle(selectedTab == tab ? Color.appPrimary : Color.appMutedForeground)
            .frame(maxWidth: .infinity, minHeight: 46)
            .contentShape(Rectangle())
        }
        .buttonStyle(FooterPressStyle())
        .accessibilityAddTraits(selectedTab == tab ? .isSelected : [])
    }
}

private struct FooterPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .opacity(configuration.isPressed ? 0.72 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
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
                        ReviewRow(title: "Keep the shoulder quiet", source: "Warm-up · 0:42", icon: .audio)
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
                    .foregroundStyle(Color.appPrimary)
                Spacer()
                HeroIcon(.audio, size: 19).foregroundStyle(Color.appPrimary)
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
                .buttonStyle(FooterPressStyle())
                Text("Scales · 0:18")
                    .font(.body(13, relativeTo: .caption))
                    .foregroundStyle(Color.appMutedForeground)
            }
        }
        .padding(22)
        .background(
            RoundedRectangle(cornerRadius: Radius.xl4, style: .continuous)
                .fill(Color.appCard)
                .shadow(color: .black.opacity(0.08), radius: 18, y: 7)
        )
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
        .padding(.vertical, 4)
    }
}

private struct FindPrototypeView: View {
    private let themes = ["Tone", "Technique", "Rhythm", "Repertoire"]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("Find")
                        .font(.display(36, .semibold, relativeTo: .largeTitle))
                    HStack(spacing: 10) {
                        HeroIcon(.tag, size: 19).foregroundStyle(Color.appMutedForeground)
                        Text("Search lessons, notes, and clips")
                            .font(.body(16, relativeTo: .body))
                            .foregroundStyle(Color.appMutedForeground)
                        Spacer()
                    }
                    .padding(.horizontal, 14)
                    .frame(height: 50)
                    .background(RoundedRectangle(cornerRadius: Radius.xl2, style: .continuous).fill(Color.appCard))
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
                                .background(RoundedRectangle(cornerRadius: Radius.xl2, style: .continuous).fill(Color.appCard))
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
                    .background(RoundedRectangle(cornerRadius: Radius.xl3, style: .continuous).fill(Color.appCard))
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

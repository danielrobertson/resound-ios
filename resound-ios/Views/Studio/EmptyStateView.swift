import SwiftUI

/// First-run studio: two action cards inviting the first capture, with the
/// brand tagline settling underneath. Recording is the flagship on iOS, so
/// it takes the accent treatment (the web leads with upload instead).
struct EmptyStateView: View {
    var onRecord: () -> Void
    var onUpload: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            ActionCard(
                icon: "mic",
                title: "Record audio",
                subtitle: "Capture the sound of today's lesson.",
                cta: "Start recording",
                accent: true,
                action: onRecord
            )
            .riseIn(delay: 0.12)

            ActionCard(
                icon: "tray.and.arrow.up",
                title: "Upload a file",
                subtitle: "Video, audio, image, or PDF.",
                cta: "Choose a file",
                action: onUpload
            )
            .riseIn(delay: 0.19)

            Text("Lessons that continue to resonate.")
                .font(.body(13, relativeTo: .footnote))
                .foregroundStyle(Color.appMutedForeground)
                .frame(maxWidth: .infinity)
                .padding(.top, 12)
                .riseIn(delay: 0.26)
        }
    }
}

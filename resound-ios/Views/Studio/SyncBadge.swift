import SwiftUI

/// Backup status for one recording, shown on its card.
///
/// Deliberately silent when everything is fine: a checkmark on every row is
/// noise, and the studio should read as a list of lessons, not a sync log.
/// Only the states the user might want to act on get a mark.
struct SyncBadge: View {
    let state: SyncState

    var body: some View {
        Group {
            switch state {
            case .synced:
                EmptyView()
            case .uploading:
                ProgressView()
                    .controlSize(.mini)
                    .accessibilityLabel("Backing up")
            case .local:
                HeroIcon(.backup, size: 15)
                    .foregroundStyle(Color.appMutedForeground.opacity(0.6))
                    .accessibilityLabel("Waiting to back up")
            case .failed:
                HeroIcon(.warning, size: 15)
                    .foregroundStyle(Color.appDestructive.opacity(0.8))
                    .accessibilityLabel("Backup failed")
            }
        }
        .animation(.settle, value: state)
    }
}

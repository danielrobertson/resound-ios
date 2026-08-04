import Foundation

/// Display formatters shared across the app.
///
/// `size` and `shortDate` mirror the web app's `formatSize` / `formatDate`
/// in `src/routes/studio.tsx` exactly — keep them in lockstep.
enum Format {
    /// "412 KB", "3.1 MB", "980 B" — mirrors the web's `formatSize`.
    static func size(_ bytes: Int64) -> String {
        if bytes < 1024 { return "\(bytes) B" }
        let kb = Double(bytes) / 1024
        if kb < 1024 { return "\(Int(kb.rounded())) KB" }
        return String(format: "%.1f MB", kb / 1024)
    }

    /// "Aug 3" — en locale, short month + day, no year.
    static func shortDate(_ date: Date) -> String {
        shortDateFormatter.string(from: date)
    }

    /// "1:07"; hours appear only at or above one hour ("1:02:07").
    static func duration(_ t: TimeInterval) -> String {
        guard t.isFinite else { return "0:00" }
        let total = max(0, Int(t))
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let seconds = total % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%d:%02d", minutes, seconds)
    }

    /// "Recording — Aug 3" (em dash, matching the brand voice).
    static func defaultTitle(for date: Date = .now) -> String {
        "Recording — \(shortDate(date))"
    }

    private static let shortDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "MMM d"
        return formatter
    }()
}

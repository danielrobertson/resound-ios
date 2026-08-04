import Foundation
import Testing
@testable import resound_ios

struct FormattersTests {
    // MARK: - Size (must mirror the web's formatSize exactly)

    @Test func sizeZeroBytes() {
        #expect(Format.size(0) == "0 B")
    }

    @Test func sizeJustUnderOneKB() {
        #expect(Format.size(1023) == "1023 B")
    }

    @Test func sizeExactlyOneKB() {
        #expect(Format.size(1024) == "1 KB")
    }

    @Test func sizeKilobytesAreRoundedWhole() {
        #expect(Format.size(412 * 1024 + 300) == "412 KB")
        #expect(Format.size(999 * 1024) == "999 KB")
    }

    @Test func sizeExactlyOneMB() {
        #expect(Format.size(1024 * 1024) == "1.0 MB")
    }

    @Test func sizeMegabytesHaveOneDecimal() {
        #expect(Format.size(Int64(3.1 * 1024 * 1024)) == "3.1 MB")
    }

    // MARK: - Duration

    @Test func durationZero() {
        #expect(Format.duration(0) == "0:00")
    }

    @Test func durationMinutesAndSeconds() {
        #expect(Format.duration(67) == "1:07")
    }

    @Test func durationWithHours() {
        #expect(Format.duration(3727) == "1:02:07")
    }

    // MARK: - Dates

    private var augustThird: Date {
        var components = DateComponents()
        components.year = 2026
        components.month = 8
        components.day = 3
        components.hour = 12
        return Calendar.current.date(from: components)!
    }

    @Test func shortDate() {
        #expect(Format.shortDate(augustThird) == "Aug 3")
    }

    @Test func defaultTitleUsesEmDash() {
        #expect(Format.defaultTitle(for: augustThird) == "Recording — Aug 3")
    }
}

import Testing
import Foundation
@testable import TZExpandCore

@Suite("Expander")
struct ExpanderTests {
    private static let refDate: Date = {
        var c = DateComponents()
        c.year = 2025; c.month = 6; c.day = 15; c.hour = 12; c.minute = 0
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        return cal.date(from: c)!
    }()

    @Test func home_pt_extras_et_gmt() {
        let cfg = ExpanderConfig(
            homeTimeZone: TimeZone(identifier: "America/Los_Angeles")!,
            additionalTimeZones: [
                TimeZone(identifier: "America/New_York")!,
                TimeZone(identifier: "Europe/London")!,
            ],
            referenceDate: Self.refDate
        )
        let parsed = TimeParser.parse("3pm")!
        #expect(Expander.expand(parsed, config: cfg) == "3pm PT (6pm ET / 11pm GMT)")
    }
    @Test func explicit_source_tz_promotes_home() {
        let cfg = ExpanderConfig(
            homeTimeZone: TimeZone(identifier: "America/Los_Angeles")!,
            additionalTimeZones: [TimeZone(identifier: "Europe/London")!],
            referenceDate: Self.refDate
        )
        let parsed = TimeParser.parse("6pm ET")!
        #expect(Expander.expand(parsed, config: cfg) == "6pm ET (3pm PT / 11pm GMT)")
    }
    @Test func source_equals_home_no_duplication() {
        let cfg = ExpanderConfig(
            homeTimeZone: TimeZone(identifier: "America/Los_Angeles")!,
            additionalTimeZones: [TimeZone(identifier: "America/New_York")!],
            referenceDate: Self.refDate
        )
        let parsed = TimeParser.parse("3pm PT")!
        #expect(Expander.expand(parsed, config: cfg) == "3pm PT (6pm ET)")
    }
    @Test func no_extras_returns_just_source() {
        let cfg = ExpanderConfig(
            homeTimeZone: TimeZone(identifier: "America/Los_Angeles")!,
            additionalTimeZones: [],
            referenceDate: Self.refDate
        )
        #expect(Expander.expand(TimeParser.parse("3pm")!, config: cfg) == "3pm PT")
    }
    @Test func thirty_minute_formatting() {
        let cfg = ExpanderConfig(
            homeTimeZone: TimeZone(identifier: "America/Los_Angeles")!,
            additionalTimeZones: [TimeZone(identifier: "America/New_York")!],
            referenceDate: Self.refDate
        )
        #expect(Expander.expand(TimeParser.parse("3:30pm")!, config: cfg) == "3:30pm PT (6:30pm ET)")
    }
}

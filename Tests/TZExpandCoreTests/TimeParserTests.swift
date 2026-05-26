import Testing
import Foundation
@testable import TZExpandCore

@Suite("TimeParser")
struct TimeParserTests {
    @Test func parses_3pm() {
        let p = TimeParser.parse("3pm")
        #expect(p?.hour == 15)
        #expect(p?.minute == 0)
        #expect(p?.sourceTimeZone == nil)
    }
    @Test func parses_3colon00pm() {
        let p = TimeParser.parse("3:00pm")
        #expect(p?.hour == 15); #expect(p?.minute == 0)
    }
    @Test func parses_3_space_pm() { #expect(TimeParser.parse("3 pm")?.hour == 15) }
    @Test func parses_3colon30_space_pm() {
        let p = TimeParser.parse("3:30 pm")
        #expect(p?.hour == 15); #expect(p?.minute == 30)
    }
    @Test func parses_3pm_PT() {
        let p = TimeParser.parse("3pm PT")
        #expect(p?.hour == 15)
        #expect(p?.sourceTimeZone?.identifier == "America/Los_Angeles")
    }
    @Test func parses_3colon00pm_PT() {
        let p = TimeParser.parse("3:00pm PT")
        #expect(p?.hour == 15)
        #expect(p?.sourceTimeZone?.identifier == "America/Los_Angeles")
    }
    @Test func parses_3_space_pm_PT() {
        let p = TimeParser.parse("3 pm PT")
        #expect(p?.hour == 15)
        #expect(p?.sourceTimeZone?.identifier == "America/Los_Angeles")
    }
    @Test func parses_24h() {
        let p = TimeParser.parse("15:00")
        #expect(p?.hour == 15); #expect(p?.minute == 0)
    }
    @Test func parses_24h_with_tz() {
        let p = TimeParser.parse("15:00 CET")
        #expect(p?.hour == 15)
        #expect(p?.sourceTimeZone?.identifier == "Europe/Paris")
    }
    @Test func parses_noon() {
        let p = TimeParser.parse("noon")
        #expect(p?.hour == 12); #expect(p?.minute == 0)
    }
    @Test func parses_midnight() { #expect(TimeParser.parse("midnight")?.hour == 0) }
    @Test func twelve_am_is_midnight() {
        #expect(TimeParser.parse("12am")?.hour == 0)
        #expect(TimeParser.parse("12:00am")?.hour == 0)
    }
    @Test func twelve_pm_is_noon() { #expect(TimeParser.parse("12pm")?.hour == 12) }
    @Test func rejects_garbage() {
        #expect(TimeParser.parse("hello") == nil)
        #expect(TimeParser.parse("") == nil)
        #expect(TimeParser.parse("25:00") == nil)
        #expect(TimeParser.parse("13pm") == nil)
        #expect(TimeParser.parse("3pm XYZ") == nil)
    }
}

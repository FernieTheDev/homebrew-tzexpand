import Foundation

public struct ParsedTime: Equatable {
    public let hour: Int          // 0-23
    public let minute: Int        // 0-59
    public let sourceTimeZone: TimeZone?
    public let matchedText: String

    public init(hour: Int, minute: Int, sourceTimeZone: TimeZone?, matchedText: String) {
        self.hour = hour
        self.minute = minute
        self.sourceTimeZone = sourceTimeZone
        self.matchedText = matchedText
    }
}

public enum TimeParser {
    /// Parses a permissive time expression. Accepts forms such as:
    /// 3pm, 3:00pm, 3 pm, 3:00 pm, 3pm PT, 3:00pm PT, 3 pm PT,
    /// 15:00, 15:00 CET, noon, midnight.
    public static func parse(_ input: String) -> ParsedTime? {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let lower = trimmed.lowercased()
        if let parsed = parseWordForm(lower, original: trimmed) { return parsed }

        // Groups: 1=hour, 2=minute(optional), 3=meridiem(optional), 4=tz token(optional)
        let pattern = #"^\s*(\d{1,2})(?::(\d{2}))?\s*([aApP][mM]?)?\s*([A-Za-z][A-Za-z/_+\-]{0,30})?\s*$"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let range = NSRange(trimmed.startIndex..., in: trimmed)
        guard let match = regex.firstMatch(in: trimmed, range: range), match.numberOfRanges >= 5 else {
            return nil
        }

        func group(_ idx: Int) -> String? {
            let r = match.range(at: idx)
            guard r.location != NSNotFound, let swiftRange = Range(r, in: trimmed) else { return nil }
            return String(trimmed[swiftRange])
        }

        guard let hourStr = group(1), var hour = Int(hourStr) else { return nil }
        let minute = group(2).flatMap { Int($0) } ?? 0
        let meridiem = group(3)?.lowercased()
        let tzToken = group(4)

        if let mer = meridiem {
            guard (1...12).contains(hour) else { return nil }
            let isPM = mer.hasPrefix("p")
            if isPM && hour < 12 { hour += 12 }
            if !isPM && hour == 12 { hour = 0 }
        } else {
            guard (0...23).contains(hour) else { return nil }
        }
        guard (0...59).contains(minute) else { return nil }

        var sourceTZ: TimeZone? = nil
        if let token = tzToken {
            let upper = token.uppercased()
            if upper == "AM" || upper == "PM" || upper == "A" || upper == "P" {
                sourceTZ = nil
            } else if let tz = TimezoneAbbreviations.timezone(forToken: token) {
                sourceTZ = tz
            } else {
                return nil
            }
        }

        return ParsedTime(hour: hour, minute: minute, sourceTimeZone: sourceTZ, matchedText: trimmed)
    }

    private static func parseWordForm(_ lower: String, original: String) -> ParsedTime? {
        let parts = lower.split(separator: " ", omittingEmptySubsequences: true).map(String.init)
        guard let first = parts.first else { return nil }
        let (h, m): (Int, Int)
        switch first {
        case "noon": (h, m) = (12, 0)
        case "midnight": (h, m) = (0, 0)
        default: return nil
        }
        var tz: TimeZone? = nil
        if parts.count == 2 {
            guard let resolved = TimezoneAbbreviations.timezone(forToken: parts[1]) else { return nil }
            tz = resolved
        } else if parts.count > 2 {
            return nil
        }
        return ParsedTime(hour: h, minute: m, sourceTimeZone: tz, matchedText: original)
    }
}

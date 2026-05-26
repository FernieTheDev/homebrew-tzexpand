import Foundation

public struct ExpanderConfig {
    public var homeTimeZone: TimeZone
    public var additionalTimeZones: [TimeZone]
    public var separator: String
    public var referenceDate: Date

    public init(
        homeTimeZone: TimeZone,
        additionalTimeZones: [TimeZone],
        separator: String = " / ",
        referenceDate: Date = Date()
    ) {
        self.homeTimeZone = homeTimeZone
        self.additionalTimeZones = additionalTimeZones
        self.separator = separator
        self.referenceDate = referenceDate
    }
}

public enum Expander {
    /// Produces a string like "3pm PT (6pm ET / 11pm GMT)".
    /// If `parsed.sourceTimeZone` is set, that TZ is used as the source and
    /// the home TZ is promoted into the parenthetical list (when not already present).
    public static func expand(_ parsed: ParsedTime, config: ExpanderConfig) -> String {
        let source = parsed.sourceTimeZone ?? config.homeTimeZone

        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = source
        let refComponents = cal.dateComponents([.year, .month, .day], from: config.referenceDate)
        var comps = DateComponents()
        comps.year = refComponents.year
        comps.month = refComponents.month
        comps.day = refComponents.day
        comps.hour = parsed.hour
        comps.minute = parsed.minute
        guard let anchor = cal.date(from: comps) else { return parsed.matchedText }

        var outputZones: [TimeZone] = []
        if parsed.sourceTimeZone != nil
            && config.homeTimeZone.identifier != source.identifier
            && !config.additionalTimeZones.contains(where: { $0.identifier == config.homeTimeZone.identifier }) {
            outputZones.append(config.homeTimeZone)
        }
        for tz in config.additionalTimeZones where tz.identifier != source.identifier {
            outputZones.append(tz)
        }

        let sourceSegment = format(anchor, in: source)
        if outputZones.isEmpty { return sourceSegment }
        let extras = outputZones.map { format(anchor, in: $0) }.joined(separator: config.separator)
        return "\(sourceSegment) (\(extras))"
    }

    private static func format(_ date: Date, in tz: TimeZone) -> String {
        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POSIX")
        df.timeZone = tz
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = tz
        let comps = cal.dateComponents([.hour, .minute], from: date)
        let minute = comps.minute ?? 0
        df.dateFormat = minute == 0 ? "ha" : "h:mma"
        let raw = df.string(from: date).lowercased()
        return "\(raw) \(TimezoneAbbreviations.label(for: tz))"
    }
}

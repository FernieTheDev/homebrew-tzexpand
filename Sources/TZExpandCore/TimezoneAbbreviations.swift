import Foundation

public enum TimezoneAbbreviations {
    /// Maps common timezone abbreviations and short names to canonical IANA identifiers.
    /// Keys are uppercased; lookup should uppercase the input first.
    public static let map: [String: String] = [
        // North America
        "PT": "America/Los_Angeles", "PST": "America/Los_Angeles", "PDT": "America/Los_Angeles",
        "MT": "America/Denver", "MST": "America/Denver", "MDT": "America/Denver",
        "CT": "America/Chicago", "CST": "America/Chicago", "CDT": "America/Chicago",
        "ET": "America/New_York", "EST": "America/New_York", "EDT": "America/New_York",
        "AKT": "America/Anchorage", "AKST": "America/Anchorage", "AKDT": "America/Anchorage",
        "HST": "Pacific/Honolulu",
        // UTC / GB / Europe
        "UTC": "UTC", "GMT": "GMT", "Z": "UTC",
        "BST": "Europe/London",
        "WET": "Europe/Lisbon", "WEST": "Europe/Lisbon",
        "CET": "Europe/Paris", "CEST": "Europe/Paris",
        "EET": "Europe/Athens", "EEST": "Europe/Athens",
        "MSK": "Europe/Moscow",
        // Asia
        "IST": "Asia/Kolkata",
        "PKT": "Asia/Karachi",
        "JST": "Asia/Tokyo",
        "KST": "Asia/Seoul",
        "SGT": "Asia/Singapore",
        "HKT": "Asia/Hong_Kong",
        // Oceania
        "AEST": "Australia/Sydney", "AEDT": "Australia/Sydney",
        "ACST": "Australia/Adelaide", "ACDT": "Australia/Adelaide",
        "AWST": "Australia/Perth",
        "NZST": "Pacific/Auckland", "NZDT": "Pacific/Auckland",
        // South America
        "BRT": "America/Sao_Paulo", "BRST": "America/Sao_Paulo",
        "ART": "America/Argentina/Buenos_Aires",
        "CLT": "America/Santiago", "CLST": "America/Santiago",
    ]

    /// Display label preferred for a given IANA identifier. Falls back to the IANA tail.
    public static let preferredAbbreviation: [String: String] = [
        "America/Los_Angeles": "PT",
        "America/Denver": "MT",
        "America/Chicago": "CT",
        "America/New_York": "ET",
        "America/Anchorage": "AKT",
        "Pacific/Honolulu": "HST",
        "UTC": "UTC",
        "GMT": "GMT",
        "Europe/London": "GMT",
        "Europe/Paris": "CET",
        "Europe/Athens": "EET",
        "Europe/Moscow": "MSK",
        "Asia/Kolkata": "IST",
        "Asia/Tokyo": "JST",
        "Asia/Seoul": "KST",
        "Asia/Singapore": "SGT",
        "Asia/Hong_Kong": "HKT",
        "Australia/Sydney": "AEST",
        "Australia/Adelaide": "ACST",
        "Australia/Perth": "AWST",
        "Pacific/Auckland": "NZST",
        "America/Sao_Paulo": "BRT",
    ]

    public static func timezone(forToken token: String) -> TimeZone? {
        let key = token.uppercased()
        if let iana = map[key], let tz = TimeZone(identifier: iana) { return tz }
        if let tz = TimeZone(abbreviation: key) { return tz }
        if let tz = TimeZone(identifier: token) { return tz }
        return nil
    }

    public static func label(for tz: TimeZone) -> String {
        if let preferred = preferredAbbreviation[tz.identifier] { return preferred }
        return tz.abbreviation() ?? tz.identifier.components(separatedBy: "/").last ?? tz.identifier
    }
}

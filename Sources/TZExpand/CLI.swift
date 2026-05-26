import Foundation
import TZExpandCore

/// Headless mode: `tzexpand <time>` prints the expansion to stdout.
/// Useful for scripting and CI smoke tests.
enum CLI {
    static func run(_ args: [String]) -> Int32 {
        guard let input = args.first else {
            FileHandle.standardError.write(Data("usage: tzexpand <time expression>\n".utf8))
            return 64
        }
        guard let parsed = TimeParser.parse(input) else {
            FileHandle.standardError.write(Data("could not parse: \(input)\n".utf8))
            return 1
        }
        let prefs = Preferences.shared
        let cfg = ExpanderConfig(
            homeTimeZone: prefs.homeTimeZone,
            additionalTimeZones: prefs.additionalTimeZones
        )
        print(Expander.expand(parsed, config: cfg))
        return 0
    }
}

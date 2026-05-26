import Foundation
import ApplicationServices
import TZExpandCore

/// Headless mode: `tzexpand <time>` prints the expansion to stdout.
/// `tzexpand --check-ax` reports Accessibility trust status.
enum CLI {
    static func run(_ args: [String]) -> Int32 {
        if args.first == "--check-ax" {
            let trusted = AXIsProcessTrusted()
            print("AXIsProcessTrusted = \(trusted)")
            return trusted ? 0 : 2
        }
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

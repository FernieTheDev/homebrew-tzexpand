import AppKit
import TZExpandCore

/// Glue: hotkey → grow selection until it parses → expand → paste.
enum Trigger {
    /// Maximum number of word-extensions to attempt when growing the
    /// selection. 4 covers "let's meet at 9 pm PT" comfortably.
    private static let maxExtensions = 4

    static func run() {
        let prefs = Preferences.shared
        let cfg = ExpanderConfig(
            homeTimeZone: prefs.homeTimeZone,
            additionalTimeZones: prefs.additionalTimeZones,
            separator: prefs.separator
        )

        // 1) Honor any explicit user selection first.
        if let s = SelectionService.currentSelection(),
           let parsed = TimeParser.parse(s) {
            PasteService.paste(Expander.expand(parsed, config: cfg))
            return
        }

        // 2) Grow the selection backwards one word at a time until a parse
        //    succeeds or we hit the cap.
        for _ in 0..<maxExtensions {
            SelectionService.extendSelectionLeftByWord()
            // Let the focused app update its selection before re-reading.
            Thread.sleep(forTimeInterval: 0.04)
            guard let s = SelectionService.currentSelection() else { continue }
            if let parsed = TimeParser.parse(s) {
                PasteService.paste(Expander.expand(parsed, config: cfg))
                return
            }
        }

        NSSound.beep()
    }
}

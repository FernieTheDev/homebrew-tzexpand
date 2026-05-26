import AppKit
import TZExpandCore

/// Glue: hotkey → selection → parse → expand → paste.
enum Trigger {
    static func run() {
        guard let raw = SelectionService.captureSelectionOrPreviousWord() else {
            NSSound.beep()
            return
        }
        guard let parsed = TimeParser.parse(raw) else {
            NSSound.beep()
            return
        }
        let prefs = Preferences.shared
        let cfg = ExpanderConfig(
            homeTimeZone: prefs.homeTimeZone,
            additionalTimeZones: prefs.additionalTimeZones,
            separator: prefs.separator
        )
        let expansion = Expander.expand(parsed, config: cfg)
        PasteService.paste(expansion)
    }
}

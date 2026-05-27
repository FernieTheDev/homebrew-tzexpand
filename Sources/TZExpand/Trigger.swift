import AppKit
import ApplicationServices
import TZExpandCore

/// Glue: hotkey → grow selection until it parses → expand → paste.
enum Trigger {
    private static let maxExtensions = 4

    static func run() {
        // If AX is revoked, silently no-op (beep). The menu bar status row
        // is the user's signal to re-grant — no popups.
        guard AXIsProcessTrusted() else {
            NSSound.beep()
            return
        }

        let prefs = Preferences.shared
        let cfg = ExpanderConfig(
            homeTimeZone: prefs.homeTimeZone,
            additionalTimeZones: prefs.additionalTimeZones,
            separator: prefs.separator
        )

        if let s = SelectionService.currentSelection(),
           let parsed = TimeParser.parse(s) {
            PasteService.paste(Expander.expand(parsed, config: cfg))
            return
        }

        for _ in 0..<maxExtensions {
            SelectionService.extendSelectionLeftByWord()
            Thread.sleep(forTimeInterval: 0.05)
            guard let s = SelectionService.currentSelection() else { continue }
            if let parsed = TimeParser.parse(s) {
                PasteService.paste(Expander.expand(parsed, config: cfg))
                return
            }
        }

        NSSound.beep()
    }
}

enum AccessibilityAlert {
    static func show() {
        let alert = NSAlert()
        alert.messageText = "TZExpand needs Accessibility access"
        alert.informativeText = """
            The hotkey can't read your text selection until you re-enable \
            Accessibility for TZExpand. This happens after every upgrade \
            because the app uses ad-hoc signing.

            Click "Open Settings" to grant access, then quit and relaunch TZExpand.
            """
        alert.addButton(withTitle: "Open Settings")
        alert.addButton(withTitle: "Cancel")
        NSApp.activate(ignoringOtherApps: true)
        let resp = alert.runModal()
        if resp == .alertFirstButtonReturn {
            let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
            NSWorkspace.shared.open(url)
        }
    }
}

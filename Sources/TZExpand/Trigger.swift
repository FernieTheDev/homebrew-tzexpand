import AppKit
import ApplicationServices
import TZExpandCore

/// Glue: hotkey → grow selection until it parses → expand → paste.
enum Trigger {
    /// Maximum number of word-extensions to attempt when growing the
    /// selection. 4 covers "let's meet at 9 pm PT" comfortably.
    private static let maxExtensions = 4

    static func run() {
        // If AX is revoked (extremely common after `brew upgrade` of ad-hoc
        // signed builds — TCC keys on CDHash, which changes every release)
        // we cannot read selections or post key events. Tell the user
        // loudly instead of silently beeping into the void.
        guard AXIsProcessTrusted() else {
            DispatchQueue.main.async { AccessibilityAlert.show() }
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

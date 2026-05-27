import AppKit
import ApplicationServices

/// Reads the currently selected text in the frontmost application via the
/// Accessibility API. Provides a primitive to extend the selection by one
/// word backwards (via synthesized ⌥⇧←) so callers can grow the capture
/// window until it parses.
enum SelectionService {
    /// Returns the currently selected text via AX, or nil if there is none.
    static func currentSelection() -> String? {
        guard AXIsProcessTrusted() else { return nil }
        let system = AXUIElementCreateSystemWide()
        var focused: CFTypeRef?
        let err = AXUIElementCopyAttributeValue(system,
                                                kAXFocusedUIElementAttribute as CFString,
                                                &focused)
        guard err == .success, let element = focused else { return nil }
        let axElement = element as! AXUIElement

        var value: CFTypeRef?
        let selErr = AXUIElementCopyAttributeValue(axElement,
                                                   kAXSelectedTextAttribute as CFString,
                                                   &value)
        guard selErr == .success, let str = value as? String, !str.isEmpty else {
            return nil
        }
        return str
    }

    /// Extends the current selection (or starts one from the cursor) by one
    /// word to the left via ⌥⇧←. Caller should `Thread.sleep` briefly after
    /// to let the focused app update its selection before re-reading.
    static func extendSelectionLeftByWord() {
        waitForModifierRelease()
        synthesize(keyCode: 0x7B /* left arrow */,
                   modifiers: [.maskAlternate, .maskShift])
    }

    private static func waitForModifierRelease() {
        let mask: NSEvent.ModifierFlags = [.command, .control, .option, .shift]
        for _ in 0..<30 {
            if NSEvent.modifierFlags.intersection(mask).isEmpty { return }
            Thread.sleep(forTimeInterval: 0.01)
        }
    }

    private static func synthesize(keyCode: CGKeyCode, modifiers: CGEventFlags) {
        let src = CGEventSource(stateID: .combinedSessionState)
        let down = CGEvent(keyboardEventSource: src, virtualKey: keyCode, keyDown: true)
        let up   = CGEvent(keyboardEventSource: src, virtualKey: keyCode, keyDown: false)
        down?.flags = modifiers
        up?.flags = modifiers
        down?.post(tap: .cghidEventTap)
        up?.post(tap: .cghidEventTap)
    }
}

import AppKit
import ApplicationServices

/// Reads the currently selected text in the frontmost application via the
/// Accessibility API. Falls back to selecting the previous word (via a
/// synthesized ⌥⇧← + ⌘C round-trip) when no selection exists.
enum SelectionService {
    enum Failure: Error {
        case noFocusedElement
        case noSelection
        case axNotAuthorized
    }

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

    /// Fallback: selects the previous "word" using ⌥⇧← so the next AX read
    /// returns it. Caller is responsible for collapsing the selection afterwards
    /// (the paste action naturally replaces it).
    static func selectPreviousWord() {
        synthesize(keyCode: 0x7B, // left arrow
                   modifiers: [.maskAlternate, .maskShift])
    }

    /// Captures whatever is currently selected (or selects the previous word
    /// first if nothing is selected), returning the captured string.
    static func captureSelectionOrPreviousWord() -> String? {
        if let s = currentSelection() { return s }
        selectPreviousWord()
        // Give the focused app a beat to update its selection.
        Thread.sleep(forTimeInterval: 0.05)
        return currentSelection()
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

import AppKit

/// Writes a string to the pasteboard and synthesizes ⌘V to paste it, then
/// restores the previous pasteboard contents after a short delay.
enum PasteService {
    static func paste(_ text: String) {
        let pb = NSPasteboard.general
        let snapshot: [[NSPasteboard.PasteboardType: Data]] = pb.pasteboardItems?.compactMap { item in
            var dict: [NSPasteboard.PasteboardType: Data] = [:]
            for type in item.types {
                if let data = item.data(forType: type) {
                    dict[type] = data
                }
            }
            return dict.isEmpty ? nil : dict
        } ?? []

        pb.clearContents()
        pb.setString(text, forType: .string)

        // Wait for the user to release the hotkey modifiers (Ctrl/Option/Shift)
        // before synthesizing ⌘V. .cghidEventTap merges our event flags with
        // the live hardware state — if Ctrl+Option are still down, Slack sees
        // ⌃⌥⌘V instead of ⌘V (which pops the Cmd menu-shortcut overlay).
        waitForModifierRelease()
        synthesizeCmdV()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            pb.clearContents()
            for entry in snapshot {
                let item = NSPasteboardItem()
                for (type, data) in entry {
                    item.setData(data, forType: type)
                }
                pb.writeObjects([item])
            }
        }
    }

    /// Polls until Ctrl/Option/Shift/Cmd are no longer physically held, up to
    /// ~300ms. Returns immediately if already clear.
    private static func waitForModifierRelease() {
        let mask: NSEvent.ModifierFlags = [.command, .control, .option, .shift]
        for _ in 0..<30 {
            let current = NSEvent.modifierFlags
            if current.intersection(mask).isEmpty { return }
            Thread.sleep(forTimeInterval: 0.01)
        }
    }

    private static func synthesizeCmdV() {
        let src = CGEventSource(stateID: .combinedSessionState)
        let v: CGKeyCode = 0x09
        let down = CGEvent(keyboardEventSource: src, virtualKey: v, keyDown: true)
        let up = CGEvent(keyboardEventSource: src, virtualKey: v, keyDown: false)
        down?.flags = .maskCommand
        up?.flags = .maskCommand
        down?.post(tap: .cghidEventTap)
        up?.post(tap: .cghidEventTap)
    }
}

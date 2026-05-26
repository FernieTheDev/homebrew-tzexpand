import AppKit

/// Writes a string to the pasteboard and synthesizes ⌘V to paste it, then
/// restores the previous pasteboard contents after a short delay.
enum PasteService {
    static func paste(_ text: String) {
        let pb = NSPasteboard.general
        // Snapshot current items.
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

        synthesizeCmdV()

        // Restore after the paste has had time to propagate.
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

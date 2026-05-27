import AppKit

/// Reads the currently selected text by snapshotting the pasteboard,
/// synthesizing ⌘C, waiting for the changeCount to bump, then restoring
/// the snapshot. Used as a fallback for apps (Slack, web inputs) that
/// don't expose AXSelectedText.
enum ClipboardCopyService {
    static func copyCurrentSelection() -> String? {
        let pb = NSPasteboard.general

        // Snapshot.
        let snapshot: [[NSPasteboard.PasteboardType: Data]] = pb.pasteboardItems?.compactMap { item in
            var dict: [NSPasteboard.PasteboardType: Data] = [:]
            for type in item.types {
                if let data = item.data(forType: type) {
                    dict[type] = data
                }
            }
            return dict.isEmpty ? nil : dict
        } ?? []
        let beforeCount = pb.changeCount

        synthesizeCmdC()

        // Wait up to ~120ms for the focused app to write to the pasteboard.
        var copied: String? = nil
        for _ in 0..<12 {
            Thread.sleep(forTimeInterval: 0.01)
            if pb.changeCount != beforeCount {
                copied = pb.string(forType: .string)
                break
            }
        }

        // Restore the snapshot regardless of whether the copy succeeded.
        DispatchQueue.main.async {
            pb.clearContents()
            for entry in snapshot {
                let item = NSPasteboardItem()
                for (type, data) in entry { item.setData(data, forType: type) }
                pb.writeObjects([item])
            }
        }

        return copied?.isEmpty == false ? copied : nil
    }

    private static func synthesizeCmdC() {
        let src = CGEventSource(stateID: .privateState)
        let c: CGKeyCode = 0x08
        let down = CGEvent(keyboardEventSource: src, virtualKey: c, keyDown: true)
        let up = CGEvent(keyboardEventSource: src, virtualKey: c, keyDown: false)
        down?.flags = .maskCommand
        up?.flags = .maskCommand
        down?.post(tap: .cghidEventTap)
        up?.post(tap: .cghidEventTap)
    }
}

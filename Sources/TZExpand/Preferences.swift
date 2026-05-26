import Foundation
import TZExpandCore

/// Lightweight UserDefaults-backed configuration store.
/// Keys are namespaced to avoid clashes if users sync `~/Library/Preferences`.
final class Preferences {
    static let shared = Preferences()

    private let defaults = UserDefaults.standard
    private enum K {
        static let home = "TZExpand.homeTimeZone"
        static let extras = "TZExpand.additionalTimeZones"
        static let separator = "TZExpand.separator"
        static let hotkeyKeyCode = "TZExpand.hotkey.keyCode"
        static let hotkeyModifiers = "TZExpand.hotkey.modifiers"
    }

    var homeTimeZone: TimeZone {
        get {
            if let id = defaults.string(forKey: K.home), let tz = TimeZone(identifier: id) { return tz }
            return TimeZone.current
        }
        set { defaults.set(newValue.identifier, forKey: K.home) }
    }

    var additionalTimeZones: [TimeZone] {
        get {
            let ids = defaults.stringArray(forKey: K.extras)
                ?? ["America/New_York", "Europe/London"]
            return ids.compactMap { TimeZone(identifier: $0) }
        }
        set {
            defaults.set(newValue.map { $0.identifier }, forKey: K.extras)
        }
    }

    var separator: String {
        get { defaults.string(forKey: K.separator) ?? " / " }
        set { defaults.set(newValue, forKey: K.separator) }
    }

    /// Hotkey key code (Carbon virtual key). Default = `T` (0x11).
    var hotkeyKeyCode: UInt32 {
        get {
            let raw = defaults.integer(forKey: K.hotkeyKeyCode)
            return raw == 0 ? 0x11 : UInt32(raw)
        }
        set { defaults.set(Int(newValue), forKey: K.hotkeyKeyCode) }
    }

    /// Hotkey modifier flags (Carbon mask). Default = control+option.
    var hotkeyModifiers: UInt32 {
        get {
            let raw = defaults.integer(forKey: K.hotkeyModifiers)
            // 4096 = controlKey, 2048 = optionKey  (Carbon HIToolbox values)
            return raw == 0 ? (4096 | 2048) : UInt32(raw)
        }
        set { defaults.set(Int(newValue), forKey: K.hotkeyModifiers) }
    }
}

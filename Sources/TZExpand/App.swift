import SwiftUI
import AppKit
import ApplicationServices
import TZExpandCore

@main
struct TZExpandApp {
    static func main() {
        // CLI mode if any args after the binary path.
        let args = Array(CommandLine.arguments.dropFirst())
        if !args.isEmpty {
            exit(CLI.run(args))
        }
        // GUI mode: launch as a SwiftUI MenuBarExtra app.
        TZExpandGUIApp.main()
    }
}

struct TZExpandGUIApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate

    var body: some Scene {
        MenuBarExtra("TZ", systemImage: "clock.badge") {
            Button("Expand selection now (⌃⌥T)") {
                Trigger.run()
            }
            Divider()
            SettingsLink {
                Text("Settings…")
            }
            Divider()
            Button("Grant Accessibility access…") {
                let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
                NSWorkspace.shared.open(url)
            }
            Divider()
            Button("Quit") { NSApp.terminate(nil) }
                .keyboardShortcut("q")
        }
        Settings {
            SettingsView()
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var hotkey: HotkeyManager?

    func applicationDidFinishLaunching(_ notification: Notification) {
        promptForAccessibilityIfNeeded()
        let prefs = Preferences.shared
        hotkey = HotkeyManager(handler: { Trigger.run() })
        hotkey?.register(keyCode: prefs.hotkeyKeyCode, modifiers: prefs.hotkeyModifiers)
    }

    private func promptForAccessibilityIfNeeded() {
        let opts = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(opts)
    }
}

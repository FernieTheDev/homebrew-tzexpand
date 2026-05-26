import SwiftUI
import ApplicationServices

/// Always-on small status row at the top of the menu showing whether
/// Accessibility is granted. Refreshes whenever the menu is opened.
struct MenuStatusView: View {
    @State private var trusted: Bool = AXIsProcessTrusted()

    var body: some View {
        Group {
            if trusted {
                Label("Accessibility granted", systemImage: "checkmark.seal.fill")
                    .foregroundStyle(.green)
            } else {
                Label("Accessibility NOT granted — re-grant below", systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
            }
        }
        .onAppear { trusted = AXIsProcessTrusted() }
        .disabled(true)
    }
}

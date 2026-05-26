import SwiftUI
import TZExpandCore

struct SettingsView: View {
    @State private var homeTZ: String = Preferences.shared.homeTimeZone.identifier
    @State private var extras: [String] = Preferences.shared.additionalTimeZones.map { $0.identifier }
    @State private var newExtra: String = ""
    @State private var separator: String = Preferences.shared.separator

    private let allTimeZones = TimeZone.knownTimeZoneIdentifiers.sorted()

    var body: some View {
        Form {
            Section("Home timezone") {
                Picker("Home", selection: $homeTZ) {
                    ForEach(allTimeZones, id: \.self) { Text($0).tag($0) }
                }
                .onChange(of: homeTZ) { new in
                    if let tz = TimeZone(identifier: new) {
                        Preferences.shared.homeTimeZone = tz
                    }
                }
            }
            Section("Additional timezones (shown in parentheses)") {
                ForEach(Array(extras.enumerated()), id: \.offset) { idx, id in
                    HStack {
                        Text(id)
                        Spacer()
                        Button(role: .destructive) {
                            extras.remove(at: idx)
                            persistExtras()
                        } label: {
                            Image(systemName: "minus.circle")
                        }
                        .buttonStyle(.borderless)
                    }
                }
                HStack {
                    Picker("Add", selection: $newExtra) {
                        Text("Select…").tag("")
                        ForEach(allTimeZones, id: \.self) { Text($0).tag($0) }
                    }
                    Button("Add") {
                        guard !newExtra.isEmpty, !extras.contains(newExtra) else { return }
                        extras.append(newExtra)
                        newExtra = ""
                        persistExtras()
                    }
                    .disabled(newExtra.isEmpty)
                }
            }
            Section("Format") {
                TextField("Separator", text: $separator)
                    .onSubmit { Preferences.shared.separator = separator }
                Text("Example: `3pm PT (6pm ET\(separator)11pm GMT)`")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            Section("Hotkey") {
                Text("Default: ⌃⌥T")
                Text("Custom hotkey UI coming soon — edit values in `UserDefaults` for now.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .frame(width: 480, height: 520)
    }

    private func persistExtras() {
        Preferences.shared.additionalTimeZones = extras.compactMap { TimeZone(identifier: $0) }
    }
}

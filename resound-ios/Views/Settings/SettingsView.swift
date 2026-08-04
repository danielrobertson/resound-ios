import SwiftUI

/// Appearance preference plus the brand's About block.
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage(ThemePreference.storageKey) private var theme: ThemePreference = .system

    var body: some View {
        NavigationStack {
            Form {
                Section("Appearance") {
                    Picker("Appearance", selection: $theme) {
                        ForEach(ThemePreference.allCases) { preference in
                            Text(preference.label).tag(preference)
                        }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                }

                Section("About") {
                    VStack(spacing: 10) {
                        WaveMark()
                            .stroke(
                                Color.appPrimary,
                                style: StrokeStyle(lineWidth: 2.4, lineCap: .round)
                            )
                            .frame(width: 36, height: 36)
                            .accessibilityHidden(true)

                        Text("resound")
                            .font(.display(26, .semibold, relativeTo: .title2))
                            .foregroundStyle(Color.appForeground)

                        Text("Lessons that continue to resonate.")
                            .font(.body(13, relativeTo: .footnote))
                            .foregroundStyle(Color.appMutedForeground)

                        Text("Version \(appVersion)")
                            .font(.body(12, relativeTo: .caption))
                            .foregroundStyle(Color.appMutedForeground.opacity(0.7))
                            .padding(.top, 2)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private var appVersion: String {
        let short = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        if let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String {
            return "\(short) (\(build))"
        }
        return short
    }
}

#Preview("Settings") {
    SettingsView()
}

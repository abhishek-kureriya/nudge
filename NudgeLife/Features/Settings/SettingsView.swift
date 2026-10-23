import SwiftUI

struct SettingsView: View {
    @Environment(\.appState) private var appState
    @AppStorage("appearance") private var appearance: String = "system"
    @State private var notificationStatus: String = "Checking..."
    @State private var showNotificationDeniedAlert = false

    var body: some View {
        List {
            // MARK: - Notifications
            Section("Notifications") {
                HStack {
                    Label("Status", systemImage: "bell.fill")
                    Spacer()
                    Text(notificationStatus)
                        .foregroundStyle(NudgeColors.textSecondary)
                }

                if notificationStatus == "Denied" {
                    Button {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        Label("Open System Settings", systemImage: "gear")
                    }
                }

                if notificationStatus == "Not Requested" {
                    Button {
                        Task {
                            _ = try? await appState?.notificationService.requestAuthorization()
                            await updateNotificationStatus()
                        }
                    } label: {
                        Label("Enable Notifications", systemImage: "bell.badge")
                    }
                }
            }

            // MARK: - Appearance
            Section("Appearance") {
                Picker("Theme", selection: $appearance) {
                    Text("System").tag("system")
                    Text("Light").tag("light")
                    Text("Dark").tag("dark")
                }
                .pickerStyle(.segmented)
            }

            // MARK: - Privacy
            Section("Privacy") {
                Label {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Your Data Stays on Device")
                            .font(NudgeTypography.cardTitle)
                        Text("Nudge Life stores all your data locally. No accounts, no cloud sync, no analytics.")
                            .font(NudgeTypography.footnote)
                            .foregroundStyle(NudgeColors.textSecondary)
                    }
                } icon: {
                    Image(systemName: "lock.shield.fill")
                        .foregroundStyle(NudgeColors.accent)
                }
            }

            // MARK: - Premium (Future)
            Section {
                Label {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Nudge Life Premium")
                            .font(NudgeTypography.cardTitle)
                        Text("Coming soon — cloud sync, widgets, and more.")
                            .font(NudgeTypography.footnote)
                            .foregroundStyle(NudgeColors.textSecondary)
                    }
                } icon: {
                    Image(systemName: "star.fill")
                        .foregroundStyle(.yellow)
                }
            } header: {
                Text("Premium")
            } footer: {
                Text("Premium features are not yet available.")
            }

            // MARK: - About
            Section("About") {
                HStack {
                    Text("Version")
                    Spacer()
                    Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0")
                        .foregroundStyle(NudgeColors.textSecondary)
                }
                HStack {
                    Text("Build")
                    Spacer()
                    Text(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1")
                        .foregroundStyle(NudgeColors.textSecondary)
                }
            }
        }
        .navigationTitle("Settings")
        .task { await updateNotificationStatus() }
        .preferredColorScheme(colorScheme)
    }

    private var colorScheme: ColorScheme? {
        switch appearance {
        case "light": .light
        case "dark": .dark
        default: nil
        }
    }

    private func updateNotificationStatus() async {
        guard let service = appState?.notificationService else { return }
        let status = await service.getAuthorizationStatus()
        notificationStatus = switch status {
        case .authorized: "Authorized"
        case .denied: "Denied"
        case .provisional: "Provisional"
        case .notDetermined: "Not Requested"
        case .ephemeral: "Ephemeral"
        @unknown default: "Unknown"
        }
    }
}

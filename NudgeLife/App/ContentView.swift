import SwiftUI

enum AppTab: Hashable {
    case today, upcoming, life, completed, settings
}

struct ContentView: View {
    @State private var selectedTab: AppTab = .today

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Today", systemImage: "sun.max.fill", value: .today) {
                NavigationStack {
                    TodayView()
                }
            }
            Tab("Upcoming", systemImage: "calendar", value: .upcoming) {
                NavigationStack {
                    UpcomingView()
                }
            }
            Tab("Life", systemImage: "square.grid.2x2.fill", value: .life) {
                NavigationStack {
                    LifeView()
                }
            }
            Tab("Done", systemImage: "checkmark.circle.fill", value: .completed) {
                NavigationStack {
                    CompletedView()
                }
            }
            Tab("Settings", systemImage: "gearshape.fill", value: .settings) {
                NavigationStack {
                    SettingsView()
                }
            }
        }
        .tint(NudgeColors.accent)
        .nudgeColorScheme()
    }
}

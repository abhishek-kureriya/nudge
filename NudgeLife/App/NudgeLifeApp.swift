import SwiftUI
import SwiftData

@main
struct NudgeLifeApp: App {
    let container: ModelContainer
    @State private var appState: AppState?
    @Environment(\.scenePhase) private var scenePhase

    init() {
        do {
            let schema = Schema([NudgeReminder.self, LifeItem.self])
            let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            container = try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.appState, appState)
                .onAppear {
                    if appState == nil {
                        appState = AppState(modelContext: container.mainContext)
                    }
                }
        }
        .modelContainer(container)
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                Task { @MainActor in
                    try? await appState?.reminderService.reconcileNotifications()
                }
            }
        }
    }
}

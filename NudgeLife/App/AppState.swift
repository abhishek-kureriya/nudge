import SwiftUI
import SwiftData

/// Central dependency container for the app's services.
/// Injected into the SwiftUI environment for access throughout the view hierarchy.
@MainActor
@Observable
final class AppState {
    let reminderService: ReminderService
    let lifeItemService: LifeItemService
    let notificationService: NotificationServiceProtocol

    init(modelContext: ModelContext) {
        let notifService = NotificationService()
        self.notificationService = notifService
        self.reminderService = ReminderService(
            modelContext: modelContext,
            notificationService: notifService
        )
        self.lifeItemService = LifeItemService(modelContext: modelContext)
    }
}

// MARK: - Environment Key

extension EnvironmentValues {
    @Entry var appState: AppState? = nil
}

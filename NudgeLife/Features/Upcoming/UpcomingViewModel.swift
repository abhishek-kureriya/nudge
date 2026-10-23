import SwiftUI
import SwiftData

/// ViewModel for the Upcoming view — groups reminders into time-based sections.
@MainActor
@Observable
final class UpcomingViewModel {
    /// Group reminders into upcoming sections.
    func groupedReminders(_ reminders: [NudgeReminder]) -> [(section: Date.UpcomingSection, reminders: [NudgeReminder])] {
        let grouped = Dictionary(grouping: reminders) { reminder in
            reminder.dueDate.upcomingSection(isAllDay: reminder.isAllDay)
        }

        return grouped
            .sorted { $0.key < $1.key }
            .map { (section: $0.key, reminders: $0.value) }
    }

    /// Toggle completion on a reminder.
    func toggleCompletion(_ reminder: NudgeReminder, service: ReminderService) async {
        do {
            if reminder.isCompleted {
                try await service.reopenReminder(reminder)
            } else {
                try await service.completeReminder(reminder)
            }
        } catch {
            // Handled by view
        }
    }
}

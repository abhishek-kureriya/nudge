import SwiftUI
import SwiftData

/// ViewModel for the Today dashboard.
@MainActor
@Observable
final class TodayViewModel {
    /// Time-of-day based greeting.
    var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12: return "Good Morning"
        case 12..<17: return "Good Afternoon"
        default: return "Good Evening"
        }
    }

    /// Formatted current date string.
    var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: Date())
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
            // Error handling will be shown via the view
        }
    }
}

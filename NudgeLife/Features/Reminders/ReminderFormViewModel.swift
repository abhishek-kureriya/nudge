import SwiftUI
import SwiftData

/// ViewModel for the reminder creation/editing form.
@MainActor
@Observable
final class ReminderFormViewModel {
    // MARK: - Form State

    var title: String = ""
    var notes: String = ""
    var dueDate: Date = Date()
    var isAllDay: Bool = false
    var notificationEnabled: Bool = true
    var category: LifeCategory?
    var relatedLifeItemID: UUID?

    // Recurrence
    var isRecurring: Bool = false
    var recurrenceFrequency: RecurrenceFrequency = .daily
    var recurrenceInterval: Int = 1

    // Validation
    var showValidationError: Bool = false
    var validationMessage: String = ""

    // State
    var isSaving: Bool = false

    /// The reminder being edited, if in edit mode.
    private var editingReminder: NudgeReminder?

    var isEditing: Bool { editingReminder != nil }

    var navigationTitle: String { isEditing ? "Edit Reminder" : "New Reminder" }

    // MARK: - Init

    /// Configure for editing an existing reminder.
    func configure(with reminder: NudgeReminder) {
        editingReminder = reminder
        title = reminder.title
        notes = reminder.notes
        dueDate = reminder.dueDate
        isAllDay = reminder.isAllDay
        notificationEnabled = reminder.notificationEnabled
        category = reminder.category
        relatedLifeItemID = reminder.relatedLifeItemID

        if let rule = reminder.recurrenceRule {
            isRecurring = true
            recurrenceFrequency = rule.frequency
            recurrenceInterval = rule.interval
        }
    }

    // MARK: - Validation

    var isValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // MARK: - Save

    /// Request notification permission contextually when user first enables notifications.
    func requestNotificationPermissionIfNeeded(notificationService: NotificationServiceProtocol) async {
        let status = await notificationService.getAuthorizationStatus()
        if status == .notDetermined {
            _ = try? await notificationService.requestAuthorization()
        }
    }

    func save(using service: ReminderService, notificationService: NotificationServiceProtocol) async -> Bool {
        // Request permission contextually when user enables notifications
        if notificationEnabled {
            await requestNotificationPermissionIfNeeded(notificationService: notificationService)
        }
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else {
            validationMessage = "Please enter a title."
            showValidationError = true
            return false
        }

        isSaving = true
        defer { isSaving = false }

        do {
            if let existing = editingReminder {
                // Update existing
                existing.title = trimmedTitle
                existing.notes = notes
                existing.dueDate = dueDate
                existing.isAllDay = isAllDay
                existing.notificationEnabled = notificationEnabled
                existing.category = category
                existing.relatedLifeItemID = relatedLifeItemID
                existing.recurrenceRule = isRecurring
                    ? RecurrenceRule(frequency: recurrenceFrequency, interval: recurrenceInterval)
                    : nil

                try await service.updateReminder(existing)
            } else {
                // Create new
                let reminder = NudgeReminder(
                    title: trimmedTitle,
                    dueDate: dueDate,
                    isAllDay: isAllDay,
                    notes: notes,
                    category: category,
                    notificationEnabled: notificationEnabled
                )
                if isRecurring {
                    reminder.recurrenceRule = RecurrenceRule(
                        frequency: recurrenceFrequency,
                        interval: recurrenceInterval
                    )
                }
                reminder.relatedLifeItemID = relatedLifeItemID

                try await service.createReminder(reminder)
            }
            return true
        } catch {
            validationMessage = "Failed to save: \(error.localizedDescription)"
            showValidationError = true
            return false
        }
    }
}

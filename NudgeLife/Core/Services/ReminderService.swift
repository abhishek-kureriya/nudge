import Foundation
import SwiftData

/// Manages reminder CRUD operations, completion, recurrence, and notification coordination.
@MainActor
@Observable
final class ReminderService {
    private let modelContext: ModelContext
    private let notificationService: NotificationServiceProtocol

    init(modelContext: ModelContext, notificationService: NotificationServiceProtocol) {
        self.modelContext = modelContext
        self.notificationService = notificationService
    }

    // MARK: - Create

    func createReminder(_ reminder: NudgeReminder) async throws {
        modelContext.insert(reminder)

        if reminder.notificationEnabled {
            let data = NotificationReminderData(from: reminder)
            let ids = try await notificationService.scheduleNotifications(for: data)
            reminder.notificationIdentifiers = ids
        }

        try modelContext.save()
    }

    // MARK: - Update

    func updateReminder(_ reminder: NudgeReminder) async throws {
        reminder.updatedAt = Date()

        if reminder.notificationEnabled {
            let data = NotificationReminderData(from: reminder)
            let ids = try await notificationService.scheduleNotifications(for: data)
            reminder.notificationIdentifiers = ids
        } else {
            await notificationService.cancelNotifications(identifiers: reminder.notificationIdentifiers)
            reminder.notificationIdentifiers = []
        }

        try modelContext.save()
    }

    // MARK: - Complete

    /// Marks a reminder as complete. For recurring reminders, creates the next occurrence.
    func completeReminder(_ reminder: NudgeReminder) async throws {
        reminder.isCompleted = true
        reminder.completedAt = Date()
        reminder.updatedAt = Date()

        // Cancel notifications for this instance
        await notificationService.cancelNotifications(identifiers: reminder.notificationIdentifiers)
        reminder.notificationIdentifiers = []

        // If recurring, create next occurrence
        if let rule = reminder.recurrenceRule,
           let nextDate = rule.nextDate(after: reminder.dueDate) {
            let next = NudgeReminder(
                title: reminder.title,
                dueDate: nextDate,
                isAllDay: reminder.isAllDay,
                notes: reminder.notes,
                notificationEnabled: reminder.notificationEnabled
            )
            next.recurrenceRule = rule
            next.relatedLifeItemID = reminder.relatedLifeItemID
            next.categoryRawValue = reminder.categoryRawValue

            try await createReminder(next)
        }

        try modelContext.save()
    }

    // MARK: - Reopen

    func reopenReminder(_ reminder: NudgeReminder) async throws {
        reminder.isCompleted = false
        reminder.completedAt = nil
        reminder.updatedAt = Date()

        if reminder.notificationEnabled {
            let data = NotificationReminderData(from: reminder)
            let ids = try await notificationService.scheduleNotifications(for: data)
            reminder.notificationIdentifiers = ids
        }

        try modelContext.save()
    }

    // MARK: - Delete

    func deleteReminder(_ reminder: NudgeReminder) async throws {
        await notificationService.cancelNotifications(identifiers: reminder.notificationIdentifiers)
        modelContext.delete(reminder)
        try modelContext.save()
    }

    // MARK: - Snooze / Reschedule

    func rescheduleReminder(_ reminder: NudgeReminder, to newDate: Date) async throws {
        reminder.dueDate = newDate
        reminder.updatedAt = Date()

        if reminder.notificationEnabled {
            let data = NotificationReminderData(from: reminder)
            let ids = try await notificationService.scheduleNotifications(for: data)
            reminder.notificationIdentifiers = ids
        }

        try modelContext.save()
    }

    /// Snooze a reminder by a duration from now.
    func snoozeReminder(_ reminder: NudgeReminder, byMinutes minutes: Int) async throws {
        let newDate = Date().addingTimeInterval(TimeInterval(minutes * 60))
        try await rescheduleReminder(reminder, to: newDate)
    }

    // MARK: - Reconciliation

    /// Called on app foreground to sync notification state with data.
    func reconcileNotifications() async throws {
        let descriptor = FetchDescriptor<NudgeReminder>(
            predicate: #Predicate<NudgeReminder> { !$0.isCompleted }
        )
        let activeReminders = try modelContext.fetch(descriptor)
        let dataList = activeReminders.map { NotificationReminderData(from: $0) }
        let updatedIDs = try await notificationService.reconcileNotifications(activeReminders: dataList)

        // Apply updated identifiers back to the model objects
        for reminder in activeReminders {
            if let newIDs = updatedIDs[reminder.id] {
                reminder.notificationIdentifiers = newIDs
            }
        }

        try modelContext.save()
    }
}

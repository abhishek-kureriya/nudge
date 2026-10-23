import Foundation
@preconcurrency import UserNotifications

/// Data extracted from a reminder for notification scheduling.
/// Sendable because it contains only value types.
struct NotificationReminderData: Sendable {
    let id: UUID
    let title: String
    let notes: String
    let dueDate: Date
    let isAllDay: Bool
    let isCompleted: Bool
    let notificationEnabled: Bool
    let notificationIdentifiers: [String]
    let recurrenceRule: RecurrenceRule?

    init(from reminder: NudgeReminder) {
        self.id = reminder.id
        self.title = reminder.title
        self.notes = reminder.notes
        self.dueDate = reminder.dueDate
        self.isAllDay = reminder.isAllDay
        self.isCompleted = reminder.isCompleted
        self.notificationEnabled = reminder.notificationEnabled
        self.notificationIdentifiers = reminder.notificationIdentifiers
        self.recurrenceRule = reminder.recurrenceRule
    }
}

/// Protocol for notification operations, enabling testability via mock injection.
protocol NotificationServiceProtocol: Sendable {
    /// Request notification authorization. Returns true if granted.
    func requestAuthorization() async throws -> Bool

    /// Get the current authorization status.
    func getAuthorizationStatus() async -> UNAuthorizationStatus

    /// Schedule notifications for a reminder. Returns the notification identifiers.
    func scheduleNotifications(for data: NotificationReminderData) async throws -> [String]

    /// Cancel specific notifications by their identifiers.
    func cancelNotifications(identifiers: [String]) async

    /// Cancel all app notifications.
    func cancelAllNotifications() async

    /// Reconcile scheduled notifications with active reminder data.
    /// Returns a mapping of reminder ID -> updated notification identifiers.
    func reconcileNotifications(activeReminders: [NotificationReminderData]) async throws -> [UUID: [String]]
}

/// Manages local notification scheduling via UNUserNotificationCenter.
final class NotificationService: NotificationServiceProtocol, @unchecked Sendable {
    private let center = UNUserNotificationCenter.current()

    /// Maximum future occurrences to schedule for recurring reminders.
    static let maxScheduledOccurrences = 5

    /// Default notification time for all-day reminders (9:00 AM).
    static let allDayNotificationHour = 9

    func requestAuthorization() async throws -> Bool {
        try await center.requestAuthorization(options: [.alert, .badge, .sound])
    }

    func getAuthorizationStatus() async -> UNAuthorizationStatus {
        await center.notificationSettings().authorizationStatus
    }

    func scheduleNotifications(for data: NotificationReminderData) async throws -> [String] {
        // Cancel existing notifications for this reminder
        if !data.notificationIdentifiers.isEmpty {
            center.removePendingNotificationRequests(withIdentifiers: data.notificationIdentifiers)
        }

        // Don't schedule if disabled or completed
        guard data.notificationEnabled, !data.isCompleted else {
            return []
        }

        // Check authorization
        let status = await getAuthorizationStatus()
        guard status == .authorized || status == .provisional else {
            return []
        }

        var identifiers: [String] = []

        if let rule = data.recurrenceRule {
            // Recurring: schedule next N occurrences
            var currentDate = data.dueDate
            for i in 0..<Self.maxScheduledOccurrences {
                if currentDate <= Date() {
                    // Skip past dates — find next future one
                    if let nextDate = rule.nextDate(after: currentDate) {
                        currentDate = nextDate
                        continue
                    } else {
                        break
                    }
                }

                let id = notificationIdentifier(for: data.id, index: i)
                try scheduleNotification(
                    id: id,
                    title: data.title,
                    body: data.notes.isEmpty ? nil : data.notes,
                    date: currentDate,
                    isAllDay: data.isAllDay
                )
                identifiers.append(id)

                if let nextDate = rule.nextDate(after: currentDate) {
                    currentDate = nextDate
                } else {
                    break
                }
            }
        } else {
            // One-time: schedule single notification
            guard data.dueDate > Date() else { return [] }

            let id = notificationIdentifier(for: data.id, index: 0)
            try scheduleNotification(
                id: id,
                title: data.title,
                body: data.notes.isEmpty ? nil : data.notes,
                date: data.dueDate,
                isAllDay: data.isAllDay
            )
            identifiers.append(id)
        }

        return identifiers
    }

    func cancelNotifications(identifiers: [String]) async {
        guard !identifiers.isEmpty else { return }
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
    }

    func cancelAllNotifications() async {
        center.removeAllPendingNotificationRequests()
    }

    func reconcileNotifications(activeReminders: [NotificationReminderData]) async throws -> [UUID: [String]] {
        let pendingRequests = await center.pendingNotificationRequests()
        let pendingIDs = Set(pendingRequests.map(\.identifier))

        // Build expected identifiers from active reminders
        var expectedIDs = Set<String>()
        for data in activeReminders where data.notificationEnabled && !data.isCompleted {
            for id in data.notificationIdentifiers {
                expectedIDs.insert(id)
            }
        }

        // Cancel orphaned notifications
        let orphanedIDs = pendingIDs.subtracting(expectedIDs)
        if !orphanedIDs.isEmpty {
            center.removePendingNotificationRequests(withIdentifiers: Array(orphanedIDs))
        }

        // Replenish notifications for reminders that need them
        var updatedIdentifiers: [UUID: [String]] = [:]
        for data in activeReminders where data.notificationEnabled && !data.isCompleted {
            let currentPending = data.notificationIdentifiers.filter { pendingIDs.contains($0) }
            let needsReplenish = data.recurrenceRule != nil
                && currentPending.count < Self.maxScheduledOccurrences

            if currentPending.isEmpty || needsReplenish {
                let newIDs = try await scheduleNotifications(for: data)
                updatedIdentifiers[data.id] = newIDs
            }
        }

        return updatedIdentifiers
    }

    // MARK: - Private Helpers

    private func notificationIdentifier(for reminderID: UUID, index: Int) -> String {
        "nudge-\(reminderID.uuidString)-\(index)"
    }

    private func scheduleNotification(
        id: String,
        title: String,
        body: String?,
        date: Date,
        isAllDay: Bool
    ) throws {
        let content = UNMutableNotificationContent()
        content.title = title
        if let body {
            content.body = body
        }
        content.sound = .default

        let triggerDate: Date
        if isAllDay {
            var components = Calendar.current.dateComponents([.year, .month, .day], from: date)
            components.hour = Self.allDayNotificationHour
            components.minute = 0
            triggerDate = Calendar.current.date(from: components) ?? date
        } else {
            triggerDate = date
        }

        let triggerComponents = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute, .second],
            from: triggerDate
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerComponents, repeats: false)

        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        center.add(request)
    }
}

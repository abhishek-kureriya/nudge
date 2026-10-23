import Testing
import Foundation
import UserNotifications
@testable import NudgeLife
import SwiftData

@Suite("ReminderService")
struct ReminderServiceTests {

    @MainActor
    private func makeService() throws -> (ReminderService, MockNotificationService, ModelContext) {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: NudgeReminder.self, LifeItem.self,
            configurations: config
        )
        let context = container.mainContext
        let mockNotif = MockNotificationService()
        let service = ReminderService(modelContext: context, notificationService: mockNotif)
        return (service, mockNotif, context)
    }

    // MARK: - CRUD

    @Test @MainActor
    func createReminder() async throws {
        let (service, mockNotif, context) = try makeService()
        let reminder = NudgeReminder(title: "Test", dueDate: Date().addingTimeInterval(3600))

        try await service.createReminder(reminder)

        let fetched = try context.fetch(FetchDescriptor<NudgeReminder>())
        #expect(fetched.count == 1)
        #expect(fetched.first?.title == "Test")
        #expect(mockNotif.scheduleCallCount == 1)
    }

    @Test @MainActor
    func createReminderWithNotificationsDisabled() async throws {
        let (service, mockNotif, _) = try makeService()
        let reminder = NudgeReminder(title: "No Notif", dueDate: Date().addingTimeInterval(3600), notificationEnabled: false)

        try await service.createReminder(reminder)

        #expect(mockNotif.scheduleCallCount == 0)
    }

    @Test @MainActor
    func deleteReminder() async throws {
        let (service, mockNotif, context) = try makeService()
        let reminder = NudgeReminder(title: "Delete Me", dueDate: Date().addingTimeInterval(3600))
        try await service.createReminder(reminder)

        try await service.deleteReminder(reminder)

        let fetched = try context.fetch(FetchDescriptor<NudgeReminder>())
        #expect(fetched.isEmpty)
        #expect(mockNotif.cancelCallCount >= 1)
    }

    // MARK: - Completion

    @Test @MainActor
    func completeReminder() async throws {
        let (service, _, _) = try makeService()
        let reminder = NudgeReminder(title: "Complete Me", dueDate: Date().addingTimeInterval(3600))
        try await service.createReminder(reminder)

        try await service.completeReminder(reminder)

        #expect(reminder.isCompleted == true)
        #expect(reminder.completedAt != nil)
    }

    @Test @MainActor
    func completeRecurringCreatesNext() async throws {
        let (service, _, context) = try makeService()
        let reminder = NudgeReminder(title: "Recurring", dueDate: Date().addingTimeInterval(3600))
        reminder.recurrenceRule = RecurrenceRule(frequency: .daily)
        try await service.createReminder(reminder)

        try await service.completeReminder(reminder)

        let all = try context.fetch(FetchDescriptor<NudgeReminder>())
        #expect(all.count == 2)

        let completed = all.filter { $0.isCompleted }
        let active = all.filter { !$0.isCompleted }
        #expect(completed.count == 1)
        #expect(active.count == 1)
        #expect(active.first?.title == "Recurring")
    }

    // MARK: - Reopen

    @Test @MainActor
    func reopenReminder() async throws {
        let (service, _, _) = try makeService()
        let reminder = NudgeReminder(title: "Reopen Me", dueDate: Date().addingTimeInterval(3600))
        try await service.createReminder(reminder)
        try await service.completeReminder(reminder)

        try await service.reopenReminder(reminder)

        #expect(reminder.isCompleted == false)
        #expect(reminder.completedAt == nil)
    }

    // MARK: - Reschedule

    @Test @MainActor
    func rescheduleReminder() async throws {
        let (service, mockNotif, _) = try makeService()
        let originalDate = Date().addingTimeInterval(3600)
        let reminder = NudgeReminder(title: "Reschedule", dueDate: originalDate)
        try await service.createReminder(reminder)

        let newDate = Date().addingTimeInterval(7200)
        try await service.rescheduleReminder(reminder, to: newDate)

        #expect(reminder.dueDate == newDate)
        #expect(mockNotif.scheduleCallCount == 2)
    }
}

// MARK: - Mock Notification Service

final class MockNotificationService: NotificationServiceProtocol, @unchecked Sendable {
    var scheduleCallCount = 0
    var cancelCallCount = 0
    var reconcileCallCount = 0
    var authorizationGranted = true

    func requestAuthorization() async throws -> Bool {
        authorizationGranted
    }

    func getAuthorizationStatus() async -> UNAuthorizationStatus {
        authorizationGranted ? .authorized : .denied
    }

    func scheduleNotifications(for data: NotificationReminderData) async throws -> [String] {
        scheduleCallCount += 1
        return ["mock-\(data.id.uuidString)-0"]
    }

    func cancelNotifications(identifiers: [String]) async {
        cancelCallCount += 1
    }

    func cancelAllNotifications() async {
        cancelCallCount += 1
    }

    func reconcileNotifications(activeReminders: [NotificationReminderData]) async throws -> [UUID: [String]] {
        reconcileCallCount += 1
        return [:]
    }
}

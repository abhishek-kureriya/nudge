import Testing
import Foundation
@testable import NudgeLife
import SwiftData

@Suite("LifeItemService")
struct LifeItemServiceTests {

    @MainActor
    private func makeService() throws -> (LifeItemService, ModelContext) {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: NudgeReminder.self, LifeItem.self,
            configurations: config
        )
        let context = container.mainContext
        let service = LifeItemService(modelContext: context)
        return (service, context)
    }

    // MARK: - CRUD

    @Test @MainActor
    func createLifeItem() throws {
        let (service, context) = try makeService()
        let item = LifeItem(title: "Passport", category: .documents)

        try service.createLifeItem(item)

        let fetched = try context.fetch(FetchDescriptor<LifeItem>())
        #expect(fetched.count == 1)
        #expect(fetched.first?.title == "Passport")
        #expect(fetched.first?.category == .documents)
    }

    @Test @MainActor
    func updateLifeItem() throws {
        let (service, _) = try makeService()
        let item = LifeItem(title: "Old Title", category: .documents)
        try service.createLifeItem(item)

        item.title = "New Title"
        try service.updateLifeItem(item)

        #expect(item.title == "New Title")
    }

    @Test @MainActor
    func deleteLifeItem() throws {
        let (service, context) = try makeService()
        let item = LifeItem(title: "Delete Me", category: .custom)
        try service.createLifeItem(item)

        try service.deleteLifeItem(item)

        let fetched = try context.fetch(FetchDescriptor<LifeItem>())
        #expect(fetched.isEmpty)
    }

    // MARK: - Archive

    @Test @MainActor
    func archiveAndUnarchive() throws {
        let (service, _) = try makeService()
        let item = LifeItem(title: "Archive Me", category: .subscriptions)
        try service.createLifeItem(item)

        try service.archiveLifeItem(item)
        #expect(item.isArchived == true)

        try service.unarchiveLifeItem(item)
        #expect(item.isArchived == false)
    }

    // MARK: - Linked Reminders

    @Test @MainActor
    func linkedReminders() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: NudgeReminder.self, LifeItem.self,
            configurations: config
        )
        let context = container.mainContext
        let service = LifeItemService(modelContext: context)

        let item = LifeItem(title: "My Lease", category: .documents)
        context.insert(item)
        try context.save()

        let reminder = NudgeReminder(title: "Renew Lease", dueDate: Date())
        reminder.relatedLifeItemID = item.id
        context.insert(reminder)
        try context.save()

        let linked = try service.linkedReminders(for: item)
        #expect(linked.count == 1)
        #expect(linked.first?.title == "Renew Lease")
    }
}

import Foundation
import SwiftData

/// Manages life item CRUD operations and relationships with reminders.
@MainActor
@Observable
final class LifeItemService {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Create

    func createLifeItem(_ item: LifeItem) throws {
        modelContext.insert(item)
        try modelContext.save()
    }

    // MARK: - Update

    func updateLifeItem(_ item: LifeItem) throws {
        item.updatedAt = Date()
        try modelContext.save()
    }

    // MARK: - Archive / Unarchive

    func archiveLifeItem(_ item: LifeItem) throws {
        item.isArchived = true
        item.updatedAt = Date()
        try modelContext.save()
    }

    func unarchiveLifeItem(_ item: LifeItem) throws {
        item.isArchived = false
        item.updatedAt = Date()
        try modelContext.save()
    }

    // MARK: - Delete

    func deleteLifeItem(_ item: LifeItem) throws {
        modelContext.delete(item)
        try modelContext.save()
    }

    // MARK: - Linked Reminders

    /// Fetch all reminders linked to a given life item.
    func linkedReminders(for item: LifeItem) throws -> [NudgeReminder] {
        let itemID = item.id
        let descriptor = FetchDescriptor<NudgeReminder>(
            predicate: #Predicate<NudgeReminder> { $0.relatedLifeItemID == itemID }
        )
        return try modelContext.fetch(descriptor)
    }
}

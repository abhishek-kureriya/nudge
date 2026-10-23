import SwiftData
import Foundation

/// A reminder or task the user wants to track.
@Model
final class NudgeReminder {
    var id: UUID
    var title: String
    var notes: String
    var dueDate: Date
    var isAllDay: Bool
    var isCompleted: Bool
    var completedAt: Date?
    var createdAt: Date
    var updatedAt: Date

    var recurrenceRule: RecurrenceRule?

    /// Stored as raw value for SwiftData predicate compatibility.
    var categoryRawValue: String?

    /// Convenience accessor for the category enum.
    var category: LifeCategory? {
        get { categoryRawValue.flatMap { LifeCategory(rawValue: $0) } }
        set { categoryRawValue = newValue?.rawValue }
    }

    /// ID-based reference to a related LifeItem (avoids @Relationship complexity).
    var relatedLifeItemID: UUID?

    var notificationEnabled: Bool
    var notificationIdentifiers: [String]

    init(
        title: String,
        dueDate: Date,
        isAllDay: Bool = false,
        notes: String = "",
        category: LifeCategory? = nil,
        notificationEnabled: Bool = true
    ) {
        self.id = UUID()
        self.title = title
        self.notes = notes
        self.dueDate = dueDate
        self.isAllDay = isAllDay
        self.isCompleted = false
        self.completedAt = nil
        self.createdAt = Date()
        self.updatedAt = Date()
        self.recurrenceRule = nil
        self.categoryRawValue = category?.rawValue
        self.relatedLifeItemID = nil
        self.notificationEnabled = notificationEnabled
        self.notificationIdentifiers = []
    }
}

import SwiftData
import Foundation

/// A life item representing an important thing the user wants to track.
@Model
final class LifeItem {
    var id: UUID
    var title: String

    /// Stored as raw value for SwiftData predicate compatibility.
    var categoryRawValue: String

    /// Convenience accessor for the category enum.
    var category: LifeCategory {
        get { LifeCategory(rawValue: categoryRawValue) ?? .custom }
        set { categoryRawValue = newValue.rawValue }
    }

    var notes: String
    var relevantDate: Date?
    var createdAt: Date
    var updatedAt: Date
    var isArchived: Bool

    init(
        title: String,
        category: LifeCategory,
        notes: String = "",
        relevantDate: Date? = nil
    ) {
        self.id = UUID()
        self.title = title
        self.categoryRawValue = category.rawValue
        self.notes = notes
        self.relevantDate = relevantDate
        self.createdAt = Date()
        self.updatedAt = Date()
        self.isArchived = false
    }
}

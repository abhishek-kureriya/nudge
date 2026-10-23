import SwiftUI
import SwiftData

/// ViewModel for the Life organizer tab.
@MainActor
@Observable
final class LifeViewModel {
    /// Count items per category from the provided list.
    func categoryCounts(from items: [LifeItem]) -> [(category: LifeCategory, count: Int)] {
        let grouped = Dictionary(grouping: items) { $0.category }
        return LifeCategory.allCases.map { cat in
            (category: cat, count: grouped[cat]?.count ?? 0)
        }
    }

    /// Filter items by category.
    func items(in category: LifeCategory, from allItems: [LifeItem]) -> [LifeItem] {
        allItems.filter { $0.category == category }
    }
}

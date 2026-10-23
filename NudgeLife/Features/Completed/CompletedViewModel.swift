import SwiftUI
import SwiftData

/// ViewModel for the Completed history view.
@MainActor
@Observable
final class CompletedViewModel {
    enum Segment: String, CaseIterable {
        case reminders = "Reminders"
        case lifeItems = "Life Items"
    }

    var selectedSegment: Segment = .reminders
}

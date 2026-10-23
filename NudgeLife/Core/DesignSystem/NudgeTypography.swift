import SwiftUI

/// Consistent typography styles for Nudge Life.
/// Built on top of the system dynamic type sizes.
enum NudgeTypography {
    /// Large titles — greeting on Today view.
    static let largeTitle = Font.largeTitle.weight(.bold)

    /// Section headers — "Overdue", "Today", "This Week".
    static let sectionHeader = Font.headline

    /// Card titles — reminder/life item names.
    static let cardTitle = Font.body.weight(.semibold)

    /// Body text — notes, descriptions.
    static let body = Font.body

    /// Secondary info — dates, categories.
    static let caption = Font.subheadline

    /// Small metadata — timestamps, counts.
    static let footnote = Font.footnote
}

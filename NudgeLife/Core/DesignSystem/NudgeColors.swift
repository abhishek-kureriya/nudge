import SwiftUI
import UIKit

/// Central color palette for Nudge Life.
/// Uses a restrained teal accent with warm neutral backgrounds.
enum NudgeColors {
    // MARK: - Accent

    /// Primary teal accent — used for interactive elements, tab bar, buttons.
    static let accent = Color("AccentColor")

    /// A lighter tint for backgrounds and secondary highlights.
    static let accentLight = Color(red: 0.220, green: 0.557, blue: 0.510).opacity(0.12)

    // MARK: - Semantic

    /// Overdue / destructive actions.
    static let overdue = Color.red

    /// Success / completed state.
    static let completed = Color.green

    /// Warning / approaching deadline.
    static let warning = Color.orange

    // MARK: - Surfaces

    /// Card / grouped background — adapts to light/dark.
    static let cardBackground = Color(UIColor.secondarySystemGroupedBackground)

    /// Primary grouped background.
    static let groupedBackground = Color(UIColor.systemGroupedBackground)

    // MARK: - Text

    /// Primary text.
    static let textPrimary = Color(UIColor.label)

    /// Secondary text — dates, subtitles.
    static let textSecondary = Color(UIColor.secondaryLabel)

    /// Tertiary text — placeholders, hints.
    static let textTertiary = Color(UIColor.tertiaryLabel)
}

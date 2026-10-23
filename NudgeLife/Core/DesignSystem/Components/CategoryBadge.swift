import SwiftUI

/// A badge displaying a category with its icon and color.
struct CategoryBadge: View {
    let category: LifeCategory
    var count: Int = 0

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: category.sfSymbol)
                .font(.title2)
                .foregroundStyle(category.color)
                .frame(width: 56, height: 56)
                .background(category.color.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))

            VStack(spacing: 2) {
                Text(category.displayName)
                    .font(NudgeTypography.footnote)
                    .foregroundStyle(NudgeColors.textPrimary)
                    .lineLimit(1)

                Text("\(count)")
                    .font(NudgeTypography.footnote)
                    .foregroundStyle(NudgeColors.textSecondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(NudgeColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(category.displayName), \(count) items")
    }
}

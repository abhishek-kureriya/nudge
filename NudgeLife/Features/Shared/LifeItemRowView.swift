import SwiftUI

/// A row displaying a life item's key information.
struct LifeItemRowView: View {
    let item: LifeItem

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: item.category.sfSymbol)
                .font(.title3)
                .foregroundStyle(item.category.color)
                .frame(width: 32, height: 32)
                .background(item.category.color.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(NudgeTypography.cardTitle)
                    .foregroundStyle(item.isArchived ? NudgeColors.textTertiary : NudgeColors.textPrimary)

                HStack(spacing: 6) {
                    Text(item.category.displayName)
                        .font(NudgeTypography.footnote)
                        .foregroundStyle(NudgeColors.textSecondary)

                    if let date = item.relevantDate {
                        Text("·")
                            .foregroundStyle(NudgeColors.textTertiary)
                        Text(date.relativeDescription)
                            .font(NudgeTypography.footnote)
                            .foregroundStyle(date.isDayBeforeToday ? NudgeColors.overdue : NudgeColors.textSecondary)
                    }
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(NudgeColors.textTertiary)
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}

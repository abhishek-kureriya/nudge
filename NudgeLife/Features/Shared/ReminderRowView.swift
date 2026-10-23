import SwiftUI

/// A row displaying a reminder's key information with a completion toggle.
struct ReminderRowView: View {
    let reminder: NudgeReminder
    var onToggleComplete: (() -> Void)?

    private var isOverdue: Bool {
        !reminder.isCompleted && reminder.dueDate.isOverdue(isAllDay: reminder.isAllDay)
    }

    var body: some View {
        HStack(spacing: 12) {
            // Completion toggle
            Button {
                onToggleComplete?()
            } label: {
                Image(systemName: reminder.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(reminder.isCompleted ? NudgeColors.completed : NudgeColors.accent)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(reminder.isCompleted ? "Mark incomplete" : "Mark complete")

            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(reminder.title)
                    .font(NudgeTypography.cardTitle)
                    .foregroundStyle(reminder.isCompleted ? NudgeColors.textTertiary : NudgeColors.textPrimary)
                    .strikethrough(reminder.isCompleted)

                HStack(spacing: 6) {
                    // Due date
                    if !reminder.isCompleted {
                        Text(reminder.dueDate.displayDescription(isAllDay: reminder.isAllDay))
                            .font(NudgeTypography.footnote)
                            .foregroundStyle(isOverdue ? NudgeColors.overdue : NudgeColors.textSecondary)
                    }

                    // Recurrence indicator
                    if reminder.recurrenceRule != nil {
                        Image(systemName: "repeat")
                            .font(.caption2)
                            .foregroundStyle(NudgeColors.textTertiary)
                    }

                    // Category
                    if let category = reminder.category {
                        Text(category.displayName)
                            .font(NudgeTypography.footnote)
                            .foregroundStyle(category.color)
                    }
                }
            }

            Spacer()

            // Overdue indicator
            if isOverdue {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundStyle(NudgeColors.overdue)
                    .accessibilityLabel("Overdue")
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}

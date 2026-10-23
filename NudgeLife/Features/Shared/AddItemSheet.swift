import SwiftUI

/// Sheet presented when the user taps the Add button.
/// Lets them choose between creating a Reminder or a Life Item.
struct AddItemSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var showReminderForm: Bool
    @Binding var showLifeItemForm: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: Theme.listSpacing) {
                Text("What would you like to add?")
                    .font(NudgeTypography.caption)
                    .foregroundStyle(NudgeColors.textSecondary)
                    .padding(.top)

                Button {
                    dismiss()
                    showReminderForm = true
                } label: {
                    addOptionCard(
                        symbol: "bell.fill",
                        title: "Reminder",
                        description: "A task or reminder with a due date"
                    )
                }
                .buttonStyle(.plain)

                Button {
                    dismiss()
                    showLifeItemForm = true
                } label: {
                    addOptionCard(
                        symbol: "square.grid.2x2.fill",
                        title: "Life Item",
                        description: "Track something important in your life"
                    )
                }
                .buttonStyle(.plain)

                Spacer()
            }
            .padding(.horizontal, Theme.horizontalPadding)
            .navigationTitle("New Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func addOptionCard(symbol: String, title: String, description: String) -> some View {
        NudgeCard {
            HStack(spacing: 16) {
                Image(systemName: symbol)
                    .font(.title2)
                    .foregroundStyle(NudgeColors.accent)
                    .frame(width: 44, height: 44)
                    .background(NudgeColors.accentLight)
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(NudgeTypography.cardTitle)
                        .foregroundStyle(NudgeColors.textPrimary)
                    Text(description)
                        .font(NudgeTypography.footnote)
                        .foregroundStyle(NudgeColors.textSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(NudgeColors.textTertiary)
            }
        }
    }
}

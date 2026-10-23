import SwiftUI

/// Detail view for a single reminder.
struct ReminderDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appState) private var appState

    let reminder: NudgeReminder
    @State private var showEditSheet = false
    @State private var showDeleteConfirmation = false

    private var isOverdue: Bool {
        !reminder.isCompleted && reminder.dueDate.isOverdue(isAllDay: reminder.isAllDay)
    }

    var body: some View {
        List {
            // MARK: - Status & Title
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(reminder.title)
                            .font(NudgeTypography.largeTitle)
                            .strikethrough(reminder.isCompleted)

                        Spacer()

                        if reminder.isCompleted {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(NudgeColors.completed)
                                .font(.title2)
                        }
                    }

                    // Status badge
                    if isOverdue {
                        Label("Overdue", systemImage: "exclamationmark.triangle.fill")
                            .font(NudgeTypography.footnote)
                            .foregroundStyle(NudgeColors.overdue)
                    }
                }
            }

            // MARK: - Details
            Section("Details") {
                // Due date
                Label {
                    VStack(alignment: .leading) {
                        Text(reminder.dueDate.displayDescription(isAllDay: reminder.isAllDay))
                        if reminder.isAllDay {
                            Text("All Day")
                                .font(NudgeTypography.footnote)
                                .foregroundStyle(NudgeColors.textTertiary)
                        }
                    }
                } icon: {
                    Image(systemName: "calendar")
                        .foregroundStyle(NudgeColors.accent)
                }

                // Recurrence
                if let rule = reminder.recurrenceRule {
                    Label {
                        Text(recurrenceDescription(rule))
                    } icon: {
                        Image(systemName: "repeat")
                            .foregroundStyle(NudgeColors.accent)
                    }
                }

                // Category
                if let category = reminder.category {
                    Label {
                        Text(category.displayName)
                    } icon: {
                        Image(systemName: category.sfSymbol)
                            .foregroundStyle(category.color)
                    }
                }

                // Notification
                Label {
                    Text(reminder.notificationEnabled ? "On" : "Off")
                } icon: {
                    Image(systemName: reminder.notificationEnabled ? "bell.fill" : "bell.slash")
                        .foregroundStyle(NudgeColors.accent)
                }
            }

            // MARK: - Notes
            if !reminder.notes.isEmpty {
                Section("Notes") {
                    Text(reminder.notes)
                        .font(NudgeTypography.body)
                }
            }

            // MARK: - Completion Info
            if let completedAt = reminder.completedAt {
                Section("Completed") {
                    Label {
                        Text(completedAt.displayDescription(isAllDay: false))
                    } icon: {
                        Image(systemName: "checkmark.circle")
                            .foregroundStyle(NudgeColors.completed)
                    }
                }
            }

            // MARK: - Actions
            Section {
                Button {
                    Task {
                        guard let service = appState?.reminderService else { return }
                        if reminder.isCompleted {
                            try? await service.reopenReminder(reminder)
                        } else {
                            try? await service.completeReminder(reminder)
                        }
                    }
                } label: {
                    Label(
                        reminder.isCompleted ? "Reopen" : "Mark Complete",
                        systemImage: reminder.isCompleted ? "arrow.uturn.backward" : "checkmark.circle"
                    )
                }

                Button {
                    showEditSheet = true
                } label: {
                    Label("Edit", systemImage: "pencil")
                }

                Button(role: .destructive) {
                    showDeleteConfirmation = true
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
        .navigationTitle("Reminder")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showEditSheet) {
            ReminderFormView(editingReminder: reminder)
        }
        .confirmationDialog("Delete Reminder", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                Task {
                    guard let service = appState?.reminderService else { return }
                    try? await service.deleteReminder(reminder)
                    dismiss()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This reminder will be permanently deleted.")
        }
    }

    private func recurrenceDescription(_ rule: RecurrenceRule) -> String {
        let interval = rule.interval
        switch rule.frequency {
        case .daily:
            return interval == 1 ? "Daily" : "Every \(interval) days"
        case .weekly:
            return interval == 1 ? "Weekly" : "Every \(interval) weeks"
        case .monthly:
            return interval == 1 ? "Monthly" : "Every \(interval) months"
        case .yearly:
            return interval == 1 ? "Yearly" : "Every \(interval) years"
        }
    }
}

import SwiftUI
import SwiftData

/// Detail view for a single life item.
struct LifeItemDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appState) private var appState
    @Environment(\.modelContext) private var modelContext

    let item: LifeItem
    @State private var showEditSheet = false
    @State private var showDeleteConfirmation = false
    @State private var showReminderForm = false
    @State private var linkedReminders: [NudgeReminder] = []

    var body: some View {
        List {
            // MARK: - Title & Category
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: item.category.sfSymbol)
                            .foregroundStyle(item.category.color)
                            .font(.title2)

                        Text(item.title)
                            .font(NudgeTypography.largeTitle)
                    }

                    Text(item.category.displayName)
                        .font(NudgeTypography.caption)
                        .foregroundStyle(item.category.color)
                }
            }

            // MARK: - Details
            if item.relevantDate != nil || !item.notes.isEmpty {
                Section("Details") {
                    if let date = item.relevantDate {
                        Label {
                            VStack(alignment: .leading) {
                                Text(date.relativeDescription)
                                if date.isDayBeforeToday {
                                    Text("Expired")
                                        .font(NudgeTypography.footnote)
                                        .foregroundStyle(NudgeColors.overdue)
                                }
                            }
                        } icon: {
                            Image(systemName: "calendar")
                                .foregroundStyle(NudgeColors.accent)
                        }
                    }

                    if !item.notes.isEmpty {
                        Text(item.notes)
                            .font(NudgeTypography.body)
                    }
                }
            }

            // MARK: - Linked Reminders
            Section("Reminders") {
                if linkedReminders.isEmpty {
                    Text("No linked reminders")
                        .font(NudgeTypography.caption)
                        .foregroundStyle(NudgeColors.textTertiary)
                } else {
                    ForEach(linkedReminders) { reminder in
                        NavigationLink(value: reminder) {
                            ReminderRowView(reminder: reminder)
                        }
                    }
                }

                Button {
                    showReminderForm = true
                } label: {
                    Label("Add Reminder", systemImage: "plus.circle")
                }
            }

            // MARK: - Actions
            Section {
                Button {
                    showEditSheet = true
                } label: {
                    Label("Edit", systemImage: "pencil")
                }

                Button {
                    do {
                        if item.isArchived {
                            try appState?.lifeItemService.unarchiveLifeItem(item)
                        } else {
                            try appState?.lifeItemService.archiveLifeItem(item)
                        }
                    } catch {
                        // Handle error
                    }
                } label: {
                    Label(
                        item.isArchived ? "Unarchive" : "Archive",
                        systemImage: item.isArchived ? "tray.and.arrow.up" : "archivebox"
                    )
                }

                Button(role: .destructive) {
                    showDeleteConfirmation = true
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }

            // MARK: - Metadata
            Section {
                Label {
                    Text("Created \(item.createdAt.relativeDescription)")
                } icon: {
                    Image(systemName: "clock")
                        .foregroundStyle(NudgeColors.textTertiary)
                }
                .font(NudgeTypography.footnote)
                .foregroundStyle(NudgeColors.textSecondary)
            }
        }
        .navigationTitle("Life Item")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showEditSheet) {
            LifeItemFormView(editingItem: item)
        }
        .sheet(isPresented: $showReminderForm) {
            ReminderFormView(editingReminder: nil)
                .onDisappear { loadLinkedReminders() }
        }
        .confirmationDialog("Delete Life Item", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                do {
                    try appState?.lifeItemService.deleteLifeItem(item)
                    dismiss()
                } catch {
                    // Handle error
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This life item will be permanently deleted.")
        }
        .onAppear { loadLinkedReminders() }
        .navigationDestination(for: NudgeReminder.self) { reminder in
            ReminderDetailView(reminder: reminder)
        }
    }

    private func loadLinkedReminders() {
        do {
            linkedReminders = try appState?.lifeItemService.linkedReminders(for: item) ?? []
        } catch {
            linkedReminders = []
        }
    }
}

import SwiftUI
import SwiftData

struct CompletedView: View {
    @Environment(\.appState) private var appState
    @State private var viewModel = CompletedViewModel()

    @Query(
        filter: #Predicate<NudgeReminder> { $0.isCompleted },
        sort: \NudgeReminder.completedAt,
        order: .reverse
    )
    private var completedReminders: [NudgeReminder]

    @Query(
        filter: #Predicate<LifeItem> { $0.isArchived },
        sort: \LifeItem.updatedAt,
        order: .reverse
    )
    private var archivedLifeItems: [LifeItem]

    @State private var reminderToDelete: NudgeReminder?
    @State private var lifeItemToDelete: LifeItem?

    var body: some View {
        VStack(spacing: 0) {
            // Segment picker
            Picker("View", selection: $viewModel.selectedSegment) {
                ForEach(CompletedViewModel.Segment.allCases, id: \.self) { segment in
                    Text(segment.rawValue).tag(segment)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, Theme.horizontalPadding)
            .padding(.vertical, 8)

            // Content
            Group {
                switch viewModel.selectedSegment {
                case .reminders:
                    completedRemindersView
                case .lifeItems:
                    archivedLifeItemsView
                }
            }
        }
        .navigationTitle("Done")
        .confirmationDialog("Delete Reminder", isPresented: .init(
            get: { reminderToDelete != nil },
            set: { if !$0 { reminderToDelete = nil } }
        ), titleVisibility: .visible) {
            Button("Delete Permanently", role: .destructive) {
                if let reminder = reminderToDelete {
                    Task { try? await appState?.reminderService.deleteReminder(reminder) }
                }
                reminderToDelete = nil
            }
            Button("Cancel", role: .cancel) { reminderToDelete = nil }
        } message: {
            Text("This cannot be undone.")
        }
        .confirmationDialog("Delete Life Item", isPresented: .init(
            get: { lifeItemToDelete != nil },
            set: { if !$0 { lifeItemToDelete = nil } }
        ), titleVisibility: .visible) {
            Button("Delete Permanently", role: .destructive) {
                if let item = lifeItemToDelete {
                    try? appState?.lifeItemService.deleteLifeItem(item)
                }
                lifeItemToDelete = nil
            }
            Button("Cancel", role: .cancel) { lifeItemToDelete = nil }
        } message: {
            Text("This cannot be undone.")
        }
    }

    // MARK: - Completed Reminders

    @ViewBuilder
    private var completedRemindersView: some View {
        if completedReminders.isEmpty {
            EmptyStateView(
                symbol: "checkmark.circle",
                title: "No Completed Reminders",
                message: "Reminders you complete will appear here."
            )
        } else {
            List {
                ForEach(completedReminders) { reminder in
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(NudgeColors.completed)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(reminder.title)
                                .font(NudgeTypography.cardTitle)
                                .foregroundStyle(NudgeColors.textSecondary)
                                .strikethrough()

                            if let completedAt = reminder.completedAt {
                                Text("Completed \(completedAt.relativeDescription)")
                                    .font(NudgeTypography.footnote)
                                    .foregroundStyle(NudgeColors.textTertiary)
                            }
                        }

                        Spacer()
                    }
                    .swipeActions(edge: .leading) {
                        Button {
                            Task { try? await appState?.reminderService.reopenReminder(reminder) }
                        } label: {
                            Label("Reopen", systemImage: "arrow.uturn.backward")
                        }
                        .tint(NudgeColors.accent)
                    }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            reminderToDelete = reminder
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
        }
    }

    // MARK: - Archived Life Items

    @ViewBuilder
    private var archivedLifeItemsView: some View {
        if archivedLifeItems.isEmpty {
            EmptyStateView(
                symbol: "archivebox",
                title: "No Archived Items",
                message: "Life items you archive will appear here."
            )
        } else {
            List {
                ForEach(archivedLifeItems) { item in
                    LifeItemRowView(item: item)
                        .swipeActions(edge: .leading) {
                            Button {
                                try? appState?.lifeItemService.unarchiveLifeItem(item)
                            } label: {
                                Label("Unarchive", systemImage: "tray.and.arrow.up")
                            }
                            .tint(NudgeColors.accent)
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                lifeItemToDelete = item
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                }
            }
            .listStyle(.insetGrouped)
        }
    }
}

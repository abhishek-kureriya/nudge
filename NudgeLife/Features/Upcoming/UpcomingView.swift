import SwiftUI
import SwiftData

struct UpcomingView: View {
    @Environment(\.appState) private var appState
    @State private var viewModel = UpcomingViewModel()
    @State private var searchText = ""

    @Query(
        filter: #Predicate<NudgeReminder> { !$0.isCompleted },
        sort: \NudgeReminder.dueDate
    )
    private var incompleteReminders: [NudgeReminder]

    @State private var showAddSheet = false
    @State private var showReminderForm = false
    @State private var showLifeItemForm = false

    private var filteredReminders: [NudgeReminder] {
        if searchText.isEmpty {
            return incompleteReminders
        }
        let query = searchText.lowercased()
        return incompleteReminders.filter { $0.title.lowercased().contains(query) }
    }

    var body: some View {
        Group {
            if incompleteReminders.isEmpty {
                EmptyStateView(
                    symbol: "calendar",
                    title: "Nothing Upcoming",
                    message: "Tap + to add your first reminder."
                )
            } else {
                List {
                    let groups = viewModel.groupedReminders(filteredReminders)
                    ForEach(groups, id: \.section) { group in
                        Section {
                            ForEach(group.reminders) { reminder in
                                NavigationLink(value: reminder) {
                                    ReminderRowView(reminder: reminder) {
                                        guard let service = appState?.reminderService else { return }
                                        Task {
                                            await viewModel.toggleCompletion(reminder, service: service)
                                        }
                                    }
                                }
                                .swipeActions(edge: .trailing) {
                                    Button(role: .destructive) {
                                        Task {
                                            try? await appState?.reminderService.deleteReminder(reminder)
                                        }
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                                .swipeActions(edge: .leading) {
                                    Button {
                                        Task {
                                            try? await appState?.reminderService.completeReminder(reminder)
                                        }
                                    } label: {
                                        Label("Complete", systemImage: "checkmark.circle")
                                    }
                                    .tint(NudgeColors.completed)
                                }
                            }
                        } header: {
                            SectionHeader(
                                title: group.section.title,
                                color: group.section == .overdue ? NudgeColors.overdue : NudgeColors.textPrimary
                            )
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .searchable(text: $searchText, prompt: "Search reminders")
            }
        }
        .navigationTitle("Upcoming")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showAddSheet = true
                } label: {
                    Image(systemName: "plus")
                        .fontWeight(.semibold)
                }
                .accessibilityLabel("Add new item")
            }
        }
        .sheet(isPresented: $showAddSheet) {
            AddItemSheet(showReminderForm: $showReminderForm, showLifeItemForm: $showLifeItemForm)
        }
        .sheet(isPresented: $showReminderForm) {
            ReminderFormView()
        }
        .sheet(isPresented: $showLifeItemForm) {
            LifeItemFormView()
        }
        .navigationDestination(for: NudgeReminder.self) { reminder in
            ReminderDetailView(reminder: reminder)
        }
    }
}

import SwiftUI
import SwiftData

struct TodayView: View {
    @Environment(\.appState) private var appState
    @State private var viewModel = TodayViewModel()

    // Overdue: incomplete, due before today
    @Query(
        filter: #Predicate<NudgeReminder> {
            !$0.isCompleted
        },
        sort: \NudgeReminder.dueDate
    )
    private var allIncompleteReminders: [NudgeReminder]

    // Life items with upcoming dates (next 7 days)
    @Query(
        filter: #Predicate<LifeItem> {
            !$0.isArchived
        },
        sort: \LifeItem.relevantDate
    )
    private var allLifeItems: [LifeItem]

    @State private var showAddSheet = false
    @State private var showReminderForm = false
    @State private var showLifeItemForm = false

    private var overdueReminders: [NudgeReminder] {
        allIncompleteReminders.filter { $0.dueDate.isDayBeforeToday }
    }

    private var todayReminders: [NudgeReminder] {
        allIncompleteReminders.filter { $0.dueDate.isToday }
    }

    private var upcomingDeadlines: [LifeItem] {
        let weekFromNow = Date().adding(days: 7)
        return allLifeItems.filter { item in
            guard let date = item.relevantDate else { return false }
            return date >= Date().startOfDay && date <= weekFromNow
        }
    }

    private var completedTodayCount: Int {
        // We can't easily query completed-today with @Query, so we show a static message
        0
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // MARK: - Header
                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.greeting)
                        .font(NudgeTypography.largeTitle)
                        .foregroundStyle(NudgeColors.textPrimary)

                    Text(viewModel.dateString)
                        .font(NudgeTypography.caption)
                        .foregroundStyle(NudgeColors.textSecondary)
                }
                .padding(.horizontal, Theme.horizontalPadding)

                // MARK: - Overdue
                if !overdueReminders.isEmpty {
                    sectionView(
                        title: "Overdue",
                        titleColor: NudgeColors.overdue,
                        reminders: overdueReminders
                    )
                }

                // MARK: - Today's Tasks
                if !todayReminders.isEmpty {
                    sectionView(
                        title: "Today",
                        reminders: todayReminders
                    )
                }

                // MARK: - Upcoming Deadlines
                if !upcomingDeadlines.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        SectionHeader(title: "Upcoming Deadlines")
                            .padding(.horizontal, Theme.horizontalPadding)

                        VStack(spacing: 8) {
                            ForEach(upcomingDeadlines) { item in
                                NavigationLink(value: item) {
                                    lifeItemRow(item)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, Theme.horizontalPadding)
                    }
                }

                // MARK: - Empty State
                if overdueReminders.isEmpty && todayReminders.isEmpty && upcomingDeadlines.isEmpty {
                    EmptyStateView(
                        symbol: "sun.max.fill",
                        title: "All Clear!",
                        message: "No tasks for today. Tap + to add a reminder."
                    )
                    .frame(maxWidth: .infinity)
                    .padding(.top, 40)
                }
            }
            .padding(.vertical)
        }
        .background(NudgeColors.groupedBackground)
        .navigationTitle("Today")
        .navigationBarTitleDisplayMode(.inline)
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

    // MARK: - Section Builder

    private func sectionView(
        title: String,
        titleColor: Color = NudgeColors.textPrimary,
        reminders: [NudgeReminder]
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeader(title: title, color: titleColor)
                .padding(.horizontal, Theme.horizontalPadding)

            VStack(spacing: 4) {
                ForEach(reminders) { reminder in
                    NavigationLink(value: reminder) {
                        ReminderRowView(reminder: reminder) {
                            guard let service = appState?.reminderService else { return }
                            Task {
                                await viewModel.toggleCompletion(reminder, service: service)
                            }
                        }
                        .padding(.horizontal, Theme.horizontalPadding)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func lifeItemRow(_ item: LifeItem) -> some View {
        NudgeCard {
            HStack(spacing: 12) {
                Image(systemName: item.category.sfSymbol)
                    .foregroundStyle(item.category.color)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 2) {
                    Text(item.title)
                        .font(NudgeTypography.cardTitle)
                        .foregroundStyle(NudgeColors.textPrimary)

                    if let date = item.relevantDate {
                        Text(date.relativeDescription)
                            .font(NudgeTypography.footnote)
                            .foregroundStyle(date.isDayBeforeToday ? NudgeColors.overdue : NudgeColors.textSecondary)
                    }
                }

                Spacer()
            }
        }
    }
}

import SwiftUI
import SwiftData

struct LifeView: View {
    @Environment(\.appState) private var appState
    @State private var viewModel = LifeViewModel()

    @Query(
        filter: #Predicate<LifeItem> { !$0.isArchived },
        sort: \LifeItem.updatedAt,
        order: .reverse
    )
    private var activeItems: [LifeItem]

    @State private var showLifeItemForm = false

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        Group {
            if activeItems.isEmpty {
                EmptyStateView(
                    symbol: "square.grid.2x2",
                    title: "No Life Items",
                    message: "Track important things like documents, subscriptions, and warranties."
                )
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Category grid
                        LazyVGrid(columns: columns, spacing: 12) {
                            let counts = viewModel.categoryCounts(from: activeItems)
                            ForEach(counts.filter { $0.count > 0 }, id: \.category) { entry in
                                NavigationLink(value: entry.category) {
                                    CategoryBadge(category: entry.category, count: entry.count)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, Theme.horizontalPadding)

                        // Recent items
                        VStack(alignment: .leading, spacing: 8) {
                            SectionHeader(title: "Recent")
                                .padding(.horizontal, Theme.horizontalPadding)

                            ForEach(activeItems.prefix(10)) { item in
                                NavigationLink(value: item) {
                                    LifeItemRowView(item: item)
                                        .padding(.horizontal, Theme.horizontalPadding)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.vertical)
                }
            }
        }
        .background(NudgeColors.groupedBackground)
        .navigationTitle("Life")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showLifeItemForm = true
                } label: {
                    Image(systemName: "plus")
                        .fontWeight(.semibold)
                }
                .accessibilityLabel("Add life item")
            }
        }
        .sheet(isPresented: $showLifeItemForm) {
            LifeItemFormView()
        }
        .navigationDestination(for: LifeCategory.self) { category in
            LifeCategoryListView(category: category)
        }
        .navigationDestination(for: LifeItem.self) { item in
            LifeItemDetailView(item: item)
        }
    }
}

/// List of life items filtered by a specific category.
struct LifeCategoryListView: View {
    let category: LifeCategory

    @Query(
        filter: #Predicate<LifeItem> { !$0.isArchived },
        sort: \LifeItem.updatedAt,
        order: .reverse
    )
    private var allActiveItems: [LifeItem]

    private var filteredItems: [LifeItem] {
        allActiveItems.filter { $0.category == category }
    }

    var body: some View {
        List {
            ForEach(filteredItems) { item in
                NavigationLink(value: item) {
                    LifeItemRowView(item: item)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(category.displayName)
        .overlay {
            if filteredItems.isEmpty {
                EmptyStateView(
                    symbol: category.sfSymbol,
                    title: "No \(category.displayName)",
                    message: "Tap + to add one."
                )
            }
        }
    }
}

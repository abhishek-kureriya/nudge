import SwiftUI

/// Form for creating or editing a life item.
struct LifeItemFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appState) private var appState

    var editingItem: LifeItem?

    @State private var title: String = ""
    @State private var category: LifeCategory = .custom
    @State private var notes: String = ""
    @State private var hasRelevantDate: Bool = false
    @State private var relevantDate: Date = Date()
    @State private var showValidationError = false
    @State private var isSaving = false

    private var isEditing: Bool { editingItem != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Title", text: $title)
                        .accessibilityLabel("Life item title")

                    Picker("Category", selection: $category) {
                        ForEach(LifeCategory.allCases) { cat in
                            Label(cat.displayName, systemImage: cat.sfSymbol)
                                .tag(cat)
                        }
                    }
                }

                Section {
                    Toggle("Relevant Date", isOn: $hasRelevantDate)

                    if hasRelevantDate {
                        DatePicker("Date", selection: $relevantDate, displayedComponents: .date)
                    }
                }

                Section {
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                        .accessibilityLabel("Life item notes")
                }
            }
            .navigationTitle(isEditing ? "Edit Life Item" : "New Life Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Save" : "Add") {
                        save()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSaving)
                    .fontWeight(.semibold)
                }
            }
            .alert("Error", isPresented: $showValidationError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Please enter a title.")
            }
            .onAppear {
                if let editingItem {
                    title = editingItem.title
                    category = editingItem.category
                    notes = editingItem.notes
                    if let date = editingItem.relevantDate {
                        hasRelevantDate = true
                        relevantDate = date
                    }
                }
            }
        }
    }

    private func save() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else {
            showValidationError = true
            return
        }

        isSaving = true
        guard let service = appState?.lifeItemService else { return }

        do {
            if let existing = editingItem {
                existing.title = trimmedTitle
                existing.category = category
                existing.notes = notes
                existing.relevantDate = hasRelevantDate ? relevantDate : nil
                try service.updateLifeItem(existing)
            } else {
                let item = LifeItem(
                    title: trimmedTitle,
                    category: category,
                    notes: notes,
                    relevantDate: hasRelevantDate ? relevantDate : nil
                )
                try service.createLifeItem(item)
            }
            dismiss()
        } catch {
            isSaving = false
            showValidationError = true
        }
    }
}

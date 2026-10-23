import SwiftUI

/// Form for creating or editing a reminder.
struct ReminderFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appState) private var appState

    @State private var viewModel = ReminderFormViewModel()

    /// Pass a reminder to enter edit mode.
    var editingReminder: NudgeReminder?

    var body: some View {
        NavigationStack {
            Form {
                // MARK: - Basic Info
                Section {
                    TextField("Title", text: $viewModel.title)
                        .accessibilityLabel("Reminder title")

                    TextField("Notes", text: $viewModel.notes, axis: .vertical)
                        .lineLimit(3...6)
                        .accessibilityLabel("Reminder notes")
                }

                // MARK: - Date & Time
                Section {
                    Toggle("All Day", isOn: $viewModel.isAllDay)

                    if viewModel.isAllDay {
                        DatePicker("Date", selection: $viewModel.dueDate, displayedComponents: .date)
                    } else {
                        DatePicker("Date & Time", selection: $viewModel.dueDate)
                    }
                }

                // MARK: - Recurrence
                Section {
                    Toggle("Repeat", isOn: $viewModel.isRecurring)

                    if viewModel.isRecurring {
                        Picker("Frequency", selection: $viewModel.recurrenceFrequency) {
                            ForEach(RecurrenceFrequency.allCases, id: \.self) { freq in
                                Text(freq.displayName).tag(freq)
                            }
                        }

                        Stepper("Every \(viewModel.recurrenceInterval)", value: $viewModel.recurrenceInterval, in: 1...99)
                    }
                }

                // MARK: - Category
                Section {
                    Picker("Category", selection: $viewModel.category) {
                        Text("None").tag(LifeCategory?.none)
                        ForEach(LifeCategory.allCases) { cat in
                            Label(cat.displayName, systemImage: cat.sfSymbol)
                                .tag(LifeCategory?.some(cat))
                        }
                    }
                }

                // MARK: - Notifications
                Section {
                    Toggle("Notification", isOn: $viewModel.notificationEnabled)
                } footer: {
                    if viewModel.notificationEnabled {
                        Text("You'll receive a notification when this reminder is due.")
                    }
                }
            }
            .navigationTitle(viewModel.navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(viewModel.isEditing ? "Save" : "Add") {
                        Task {
                            guard let appState else { return }
                            if await viewModel.save(using: appState.reminderService, notificationService: appState.notificationService) {
                                dismiss()
                            }
                        }
                    }
                    .disabled(!viewModel.isValid || viewModel.isSaving)
                    .fontWeight(.semibold)
                }
            }
            .alert("Error", isPresented: $viewModel.showValidationError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.validationMessage)
            }
            .onAppear {
                if let editingReminder {
                    viewModel.configure(with: editingReminder)
                }
            }
        }
    }
}

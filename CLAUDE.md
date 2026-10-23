# Nudge Life — CLAUDE.md

> AI agent instructions for working on this codebase. Read this before making any changes.
> Tool-agnostic version: [`agent.md`](agent.md). Architecture deep-dive: [`ARCHITECTURE.md`](ARCHITECTURE.md).

## Project Identity

**Nudge Life** — "Remember what matters. Stay ahead of life."

A privacy-first iOS reminder and life organizer. Native Swift/SwiftUI, local-only, no accounts, no analytics. The app should feel simple, reliable, and premium — not clever or complicated.

## Build & Run

```bash
xcodegen generate                    # Generate .xcodeproj from project.yml
xcodebuild -project NudgeLife.xcodeproj -scheme NudgeLife \
  -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
xcodebuild ... test                  # Run all tests
```

Always run `xcodegen generate` after adding/removing/renaming Swift files.

---

## Architecture Rules

### DO

- **Use the existing feature-oriented structure.** Each feature lives in `Features/<Name>/` with its View and ViewModel. Shared components go in `Features/Shared/` or `Core/DesignSystem/Components/`.
- **Use `@Query` in views for reading data.** SwiftData `@Query` provides automatic reactive updates. Use it for list screens.
- **Use `@Observable` ViewModels for write logic.** Forms, complex interactions, and multi-step operations (complete + create next recurrence) go through ViewModels that call services.
- **Use services for all data mutations.** Never insert/delete/save `ModelContext` directly from views. Always go through `ReminderService` or `LifeItemService`.
- **Coordinate notifications through `ReminderService`.** The service handles scheduling/cancelling notifications whenever reminders change. Don't call `NotificationService` from views directly.
- **Mark all ViewModels and services `@MainActor`.** `ModelContext` is not `Sendable`. Everything touching it must run on the main actor.
- **Use `NotificationReminderData` to cross actor boundaries.** Extract a Sendable struct from `NudgeReminder` before passing to `NotificationServiceProtocol` methods.
- **Store category as `categoryRawValue: String`.** SwiftData on iOS 18 cannot use enums in `#Predicate`. Use the raw String property for queries and the computed `category` property for display.
- **Use UUID-based references between models.** `NudgeReminder.relatedLifeItemID: UUID?` instead of `@Relationship`. Fetch linked items via `FetchDescriptor` predicate.
- **Use the design system.** Colors from `NudgeColors`, fonts from `NudgeTypography`, spacing from `Theme`. Don't hardcode colors or font sizes.
- **Write tests for business logic.** Recurrence calculations, service operations, and date edge cases must have tests. Use in-memory `ModelContainer` and `MockNotificationService` for test isolation.
- **Preserve completion history for recurring reminders.** Use the complete-and-create-new pattern: mark current instance complete, create a fresh `NudgeReminder` for the next occurrence.
- **Request notification permission contextually.** Ask when the user first enables notifications on a reminder, not at app launch.
- **Handle all error states.** Show alerts for save failures. Show empty states for empty lists. Handle notification permission denied gracefully.
- **Support accessibility.** Dynamic Type, VoiceOver labels, minimum 44pt touch targets, don't communicate urgency using color alone (always pair with text or icons).

### DON'T

- **Don't add third-party dependencies.** No SPM packages, no CocoaPods. Everything uses native Apple frameworks.
- **Don't add network requests.** This is a local-only app. No analytics, no telemetry, no cloud sync (yet).
- **Don't use `@Relationship` in SwiftData models.** It causes cascade-delete bugs and schema migration issues. Use UUID references.
- **Don't use enums directly in `#Predicate`.** Store raw String values and use those for queries.
- **Don't pass `@Model` objects across actor boundaries.** They are not `Sendable`. Extract value types first.
- **Don't force-unwrap.** Use `guard let`, `if let`, or nil-coalescing. The only exception is tests with known-good test data.
- **Don't put business logic in view `body`.** Extract to ViewModel methods or service calls.
- **Don't create massive view files.** Break views into smaller components. Extract reusable pieces to `Core/DesignSystem/Components/` or `Features/Shared/`.
- **Don't schedule notifications for completed reminders.** Always check `isCompleted` and `notificationEnabled` before scheduling.
- **Don't display controls for unimplemented features as if they work.** If a feature isn't built yet, either omit the UI or clearly label it as "Coming Soon". Never show a button that does nothing.
- **Don't use `Date()` or `Date.now` in tests for assertions.** Tests must be deterministic. Create specific dates with `DateComponents`.
- **Don't hardcode date formats.** Use `DateFormatter` or the `Date` extension methods. Respect the user's locale.
- **Don't modify `project.yml` without regenerating.** Always run `xcodegen generate` after changes.
- **Don't edit `.xcodeproj` directly.** It is generated. All project configuration goes in `project.yml`.
- **Don't add sample/demo data to production builds.** Sample data is for previews and tests only.
- **Don't claim cloud sync, backups, or premium features exist.** They are not implemented. The Settings screen explicitly marks Premium as "Coming soon."

---

## Data Model Summary

### NudgeReminder (@Model)
Core reminder/task. Fields: `id`, `title`, `notes`, `dueDate`, `isAllDay`, `isCompleted`, `completedAt`, `createdAt`, `updatedAt`, `recurrenceRule: RecurrenceRule?`, `categoryRawValue: String?`, `relatedLifeItemID: UUID?`, `notificationEnabled`, `notificationIdentifiers: [String]`.

### LifeItem (@Model)
Life organizer item. Fields: `id`, `title`, `categoryRawValue: String`, `notes`, `relevantDate: Date?`, `createdAt`, `updatedAt`, `isArchived`.

### RecurrenceRule (Codable struct)
Stored as composite attribute on NudgeReminder. Fields: `frequency` (daily/weekly/monthly/yearly), `interval: Int`, `selectedWeekdays: [Int]?`, `endDate: Date?`. Has `nextDate(after:)` method with end-of-month clamping and leap-year handling.

### LifeCategory (String enum)
Categories: `billsAndPayments`, `subscriptions`, `documents`, `warranties`, `appointments`, `homeAndMaintenance`, `custom`. Each has `displayName`, `sfSymbol`, `color`.

---

## File Organization

```
NudgeLife/
├── App/                    Entry point, TabView root, DI container
├── Core/
│   ├── Models/             @Model classes + value types (4 files)
│   ├── Services/           Business logic + notifications (3 files)
│   ├── DesignSystem/       Theme, Colors, Typography + Components/
│   └── Extensions/         Date+Extensions, View+Extensions
└── Features/
    ├── Today/              Dashboard (View + ViewModel)
    ├── Upcoming/           Chronological list (View + ViewModel)
    ├── Life/               Category grid, CRUD, detail (4 files)
    ├── Reminders/          Forms + detail (3 files)
    ├── Completed/          History (View + ViewModel)
    ├── Settings/           App configuration (1 file)
    └── Shared/             AddItemSheet, row views (3 files)
```

**Adding a new feature:** Create `Features/<Name>/` with `<Name>View.swift` and optionally `<Name>ViewModel.swift`. Register in `ContentView.swift` if it's a new tab, or navigate to it from an existing screen.

**Adding a new model:** Create in `Core/Models/`. Add to the `Schema` array in `NudgeLifeApp.swift`. Run `xcodegen generate`.

**Adding a new service:** Create in `Core/Services/`. Wire into `AppState.swift`. Use protocol for testability.

**Adding a new component:** Create in `Core/DesignSystem/Components/`.

---

## Notification Rules

- iOS limits apps to **64 scheduled local notifications**.
- Recurring reminders schedule **next 5 occurrences** each.
- Reconciliation runs on every `scenePhase == .active` (app foreground).
- Notification identifiers follow the format: `nudge-{reminderUUID}-{index}`.
- All-day reminders trigger at **9:00 AM**.
- Permission is requested **contextually** on first notification enable.
- The app must remain fully functional if notification permission is denied.

---

## Concurrency Rules (Swift 6)

- `@Observable` ViewModels → `@MainActor`
- Services touching `ModelContext` → `@MainActor`
- `NotificationService` → `@unchecked Sendable` (wraps thread-safe `UNUserNotificationCenter`)
- Cross-actor data → use `NotificationReminderData` (Sendable value type)
- `RecurrenceRule`, `RecurrenceFrequency`, `LifeCategory` → `Sendable`

---

## Testing Patterns

- **Unit tests:** Swift Testing framework (`@Test`, `#expect`, `@Suite`)
- **Isolation:** In-memory `ModelConfiguration(isStoredInMemoryOnly: true)`
- **Mocking:** `MockNotificationService` implements `NotificationServiceProtocol`
- **UI tests:** XCTest with `XCUIApplication`
- **Import:** Always `@testable import NudgeLife` in test files
- **Import:** Add `import UserNotifications` when referencing `UNAuthorizationStatus`

---

## Product Principles (for all decisions)

1. **Simplicity** — common actions should require minimal taps
2. **Reliability** — reminders must be scheduled and managed predictably
3. **Clarity** — users should immediately understand what needs attention
4. **Privacy** — personal information stays on the device
5. **Accessibility** — support Dynamic Type, VoiceOver, sufficient contrast
6. **Extensibility** — future premium features must not require rewriting core
7. **Honesty** — never display controls that imply a feature works when it doesn't

---

## Related Files

| File | Purpose |
|------|---------|
| [`agent.md`](agent.md) | Tool-agnostic AI agent instructions (same rules, works with any AI tool) |
| [`ARCHITECTURE.md`](ARCHITECTURE.md) | Detailed technical architecture, diagrams, design decisions |
| [`README.md`](README.md) | User-facing setup, features list, known limitations |
| [`project.yml`](project.yml) | XcodeGen project spec — single source of truth for build config |

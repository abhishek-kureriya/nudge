# Nudge Life — Agent Instructions

> Universal AI agent instructions for this codebase.
> Tool-specific versions: [`CLAUDE.md`](CLAUDE.md) (Claude Code — auto-loaded).

---

## What Is This Project?

**Nudge Life** — "Remember what matters. Stay ahead of life."

A privacy-first iOS reminder and life organizer. Built with native Swift 6.4, SwiftUI, and SwiftData. No third-party dependencies. No backend. No accounts. All data stays on-device.

- **Deployment target:** iOS 18.0
- **Project generation:** [XcodeGen](https://github.com/yonaskolb/XcodeGen) — `project.yml` is the source of truth, `.xcodeproj` is generated
- **Concurrency:** Swift 6 strict concurrency (`@MainActor`, `Sendable`)
- **Architecture:** Feature-oriented MVVM with service layer

See [`ARCHITECTURE.md`](ARCHITECTURE.md) for the full technical design.

---

## Quick Start

```bash
xcodegen generate        # Required after any file add/remove/rename
open NudgeLife.xcodeproj # Open in Xcode, select iPhone simulator, ⌘R

# Or build from CLI:
xcodebuild -project NudgeLife.xcodeproj -scheme NudgeLife \
  -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build

# Run tests:
xcodebuild -project NudgeLife.xcodeproj -scheme NudgeLife \
  -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test
```

---

## Project Structure

```
nudge/
├── CLAUDE.md               ← Claude Code instructions (auto-loaded)
├── agent.md                ← This file — tool-agnostic AI instructions
├── ARCHITECTURE.md         ← Technical architecture deep-dive
├── README.md               ← Setup, features, limitations
├── project.yml             ← XcodeGen spec (source of truth for .xcodeproj)
├── NudgeLife/
│   ├── App/                Entry point, TabView, DI container (AppState)
│   ├── Core/
│   │   ├── Models/         SwiftData @Model classes + value types
│   │   ├── Services/       Business logic (ReminderService, LifeItemService, NotificationService)
│   │   ├── DesignSystem/   Theme, NudgeColors, NudgeTypography + Components/
│   │   └── Extensions/     Date+Extensions, View+Extensions
│   └── Features/
│       ├── Today/          Dashboard
│       ├── Upcoming/       Chronological list with sections
│       ├── Life/           Category grid, CRUD, detail views
│       ├── Reminders/      Create/edit forms, detail view
│       ├── Completed/      History with restore/delete
│       ├── Settings/       Notification status, appearance, about
│       └── Shared/         AddItemSheet, row components
├── NudgeLifeTests/         Unit tests (Swift Testing framework)
└── NudgeLifeUITests/       UI smoke tests (XCTest)
```

---

## The Rules

### ✅ DO

1. **Follow the existing patterns.** Read neighboring files before adding new ones. Match the style.
2. **Use services for all data mutations.** `ReminderService` and `LifeItemService` handle CRUD, completion, archiving. Never call `modelContext.insert/delete/save` from views.
3. **Use `@Query` in views for reading data.** It gives free reactive updates from SwiftData.
4. **Use `@Observable` ViewModels for write logic.** Forms, multi-step operations, grouping — these go in ViewModels.
5. **Use the design system.** `NudgeColors` for colors, `NudgeTypography` for fonts, `Theme` for spacing. No hardcoded values.
6. **Mark ViewModels and services `@MainActor`.** `ModelContext` is not `Sendable` — everything touching it stays on the main actor.
7. **Use `NotificationReminderData` to cross actor boundaries.** Extract Sendable values from `@Model` objects before passing to async services.
8. **Store categories as `categoryRawValue: String`.** SwiftData can't use enums in `#Predicate`. Use raw values for queries, computed properties for display.
9. **Use UUID references between models.** `relatedLifeItemID: UUID?` — not `@Relationship`.
10. **Write tests for new logic.** Use in-memory `ModelContainer` and `MockNotificationService`. Keep tests deterministic.
11. **Handle errors and empty states.** Every list screen has an empty state. Save failures show alerts.
12. **Support accessibility.** Dynamic Type, VoiceOver labels, 44pt touch targets, color + text/icon for urgency.
13. **Run `xcodegen generate` after adding/removing files.** The `.xcodeproj` is generated — don't edit it directly.

### ❌ DON'T

1. **Don't add third-party packages.** Zero external dependencies. Apple frameworks only.
2. **Don't add network requests.** No analytics, no telemetry, no API calls. Local-only.
3. **Don't use `@Relationship` in SwiftData.** Known cascade-delete bugs. UUID references are the pattern here.
4. **Don't pass `@Model` objects across actors.** Not `Sendable`. Extract value types first.
5. **Don't force-unwrap** outside of test helpers with known-good data.
6. **Don't put business logic in view `body`.** Extract to ViewModel or service.
7. **Don't fake features.** No buttons that do nothing. Label unbuilt features as "Coming Soon" or omit them.
8. **Don't edit `.xcodeproj` directly.** Edit `project.yml` and regenerate.
9. **Don't hardcode dates or formats.** Use `DateFormatter`, `Calendar`, and the `Date` extensions.
10. **Don't add sample data to production.** Preview/test only.

---

## Data Models (Quick Reference)

| Model | Type | Key Fields |
|-------|------|-----------|
| `NudgeReminder` | `@Model` | `id`, `title`, `notes`, `dueDate`, `isAllDay`, `isCompleted`, `completedAt`, `recurrenceRule?`, `categoryRawValue?`, `relatedLifeItemID?`, `notificationEnabled`, `notificationIdentifiers` |
| `LifeItem` | `@Model` | `id`, `title`, `categoryRawValue`, `notes`, `relevantDate?`, `isArchived` |
| `RecurrenceRule` | Codable struct | `frequency`, `interval`, `selectedWeekdays?`, `endDate?` + `nextDate(after:)` |
| `LifeCategory` | String enum | 7 cases with `displayName`, `sfSymbol`, `color` |

---

## Key Patterns

### Recurring Reminders → Complete-and-Create-New
When a recurring reminder is completed, the current instance is marked complete (preserving history) and a **new** `NudgeReminder` is created for the next occurrence. This keeps the Completed tab as a true history.

### Notifications → Schedule Next 5, Reconcile on Foreground
iOS caps apps at 64 local notifications. Recurring reminders schedule the next 5 occurrences. On every app foreground (`scenePhase == .active`), orphaned notifications are cancelled and gaps are replenished.

### Notification Permission → Contextual
Permission is requested the first time a user enables notifications on a reminder — not at app launch. This gives the prompt context and improves grant rates.

### DI → AppState via @Environment
`AppState` holds all services and is injected via `@Environment(\.appState)`. Views access services through it.

---

## Product Principles

Every change should align with these:

1. **Simplicity** — minimal taps for common actions
2. **Reliability** — reminders work predictably
3. **Clarity** — obvious what needs attention
4. **Privacy** — all data stays on-device
5. **Accessibility** — works for everyone
6. **Extensibility** — core doesn't need rewriting for future features
7. **Honesty** — never pretend something works when it doesn't

---

## Related Files

| File | Purpose |
|------|---------|
| [`CLAUDE.md`](CLAUDE.md) | Claude Code-specific instructions (auto-loaded by Claude Code) |
| [`ARCHITECTURE.md`](ARCHITECTURE.md) | Detailed technical architecture, diagrams, design decisions |
| [`README.md`](README.md) | User-facing setup, features list, known limitations |
| [`project.yml`](project.yml) | XcodeGen project spec — the single source of truth for build config |

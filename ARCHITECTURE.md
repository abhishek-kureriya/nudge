# Nudge Life — Architecture

## Overview

Nudge Life is a native iOS application built with SwiftUI and SwiftData. It follows a feature-oriented MVVM architecture with a service layer for business logic and notification management.

## Technology Stack

| Layer | Technology |
|-------|-----------|
| UI | SwiftUI |
| Persistence | SwiftData (@Model, @Query) |
| Notifications | UNUserNotificationCenter |
| Testing | Swift Testing (unit), XCTest (UI) |
| Project Generation | XcodeGen |
| Minimum Deployment | iOS 18.0 |
| Language | Swift 6.4 (strict concurrency) |

## Architecture Diagram

```
┌─────────────────────────────────────────────────────┐
│  SwiftUI Views                                       │
│  @Query for reactive data, @State for local state   │
│  ┌────────┐ ┌────────┐ ┌──────┐ ┌────────┐ ┌─────┐│
│  │ Today  │ │Upcoming│ │ Life │ │Complete│ │Sett.││
│  └───┬────┘ └───┬────┘ └──┬───┘ └───┬────┘ └─────┘│
│      │          │         │         │               │
│  @Observable ViewModels (@MainActor)                │
│  Form validation, complex interactions, grouping    │
│  ┌──────────┐ ┌──────────┐ ┌────────────────────┐  │
│  │ TodayVM  │ │UpcomingVM│ │ReminderFormVM etc. │  │
│  └────┬─────┘ └────┬─────┘ └─────────┬──────────┘  │
│       └──────────┬──┘                 │             │
│  Service Layer (@MainActor)                         │
│  ┌───────────────┐ ┌──────────────┐ ┌────────────┐ │
│  │ReminderService│ │LifeItemSvc   │ │NotifService│ │
│  │ CRUD+complete │ │ CRUD+archive │ │ schedule   │ │
│  │ +recurrence   │ │ +linked      │ │ cancel     │ │
│  └───────┬───────┘ └──────┬───────┘ │ reconcile  │ │
│          │                │         └────────────┘ │
│  SwiftData Layer                                    │
│  ┌───────────────┐ ┌──────────────┐                │
│  │NudgeReminder  │ │LifeItem      │                │
│  │ @Model        │ │ @Model       │                │
│  └───────────────┘ └──────────────┘                │
│                                                     │
│  AppState (DI Container, @Environment)              │
└─────────────────────────────────────────────────────┘
```

## Key Design Decisions

### 1. Hybrid @Query + ViewModel

- **Read path**: `@Query` in SwiftUI views provides automatic reactive updates when SwiftData models change. No manual refresh needed.
- **Write path**: `@Observable` ViewModels call services for mutations. The `@Query` auto-refreshes.
- **Why not pure MVVM**: `@Query` cannot be used outside SwiftUI views. Manual `FetchDescriptor` fetching requires explicit refresh after every mutation — fragile and error-prone.

### 2. UUID-Based Relationships

`NudgeReminder.relatedLifeItemID: UUID?` instead of `@Relationship`:
- SwiftData `@Relationship` has known issues with cascade deletes
- UUID references are simpler, testable, and avoid schema migration headaches
- Linked reminders are fetched via `FetchDescriptor` predicate on `relatedLifeItemID`

### 3. categoryRawValue + Computed category

SwiftData on iOS 18 cannot use enum types in `#Predicate`. We store `categoryRawValue: String` and provide a computed `category: LifeCategory` property. This enables filtering by category in queries.

### 4. Complete-and-Create-New for Recurrence

When a recurring reminder is completed:
1. Current instance is marked complete (preserving history)
2. A new `NudgeReminder` is created for the next occurrence
3. Notifications are scheduled for the new instance

This preserves full completion history and avoids complex state on a single object.

### 5. NotificationReminderData (Sendable Bridge)

`@Model` classes are not `Sendable` in Swift 6. To pass reminder data to `NotificationServiceProtocol` (which crosses actor boundaries), we extract a `NotificationReminderData` struct containing only value types. This is created on the main actor and safely sent to the notification service.

### 6. Contextual Notification Permission

Permission is not requested at app launch. It's requested the first time a user enables notifications on a reminder. This gives context and improves grant rates.

## Data Models

### NudgeReminder (@Model)

| Field | Type | Purpose |
|-------|------|---------|
| id | UUID | Stable identifier |
| title | String | Display name |
| notes | String | Optional details |
| dueDate | Date | When it's due |
| isAllDay | Bool | All-day vs. timed |
| isCompleted | Bool | Completion state |
| completedAt | Date? | When completed |
| createdAt | Date | Creation timestamp |
| updatedAt | Date | Last modification |
| recurrenceRule | RecurrenceRule? | Codable composite attribute |
| categoryRawValue | String? | For predicate queries |
| relatedLifeItemID | UUID? | Link to LifeItem |
| notificationEnabled | Bool | Whether to schedule notifications |
| notificationIdentifiers | [String] | Tracked UNNotificationRequest IDs |

### LifeItem (@Model)

| Field | Type | Purpose |
|-------|------|---------|
| id | UUID | Stable identifier |
| title | String | Display name |
| categoryRawValue | String | Category for queries |
| notes | String | Details |
| relevantDate | Date? | Key date (expiry, renewal) |
| createdAt | Date | Creation timestamp |
| updatedAt | Date | Last modification |
| isArchived | Bool | Soft delete / archive |

### RecurrenceRule (Codable struct)

| Field | Type | Purpose |
|-------|------|---------|
| frequency | RecurrenceFrequency | daily/weekly/monthly/yearly |
| interval | Int | Every N periods (min 1) |
| selectedWeekdays | [Int]? | For weekly: 1=Sun..7=Sat |
| endDate | Date? | Stop recurring after this date |

## Notification Strategy

- **Single reminder**: One `UNCalendarNotificationTrigger` at dueDate
- **All-day**: Trigger at 9:00 AM on the day
- **Recurring**: Schedule next 5 occurrences, replenish on app foreground
- **iOS limit**: 64 scheduled notifications max → ~12 concurrent recurring reminders
- **Reconciliation**: On every `scenePhase == .active`, cancel orphans and replenish

## Testing Strategy

- **Swift Testing framework** for unit tests (`@Test`, `#expect`)
- **In-memory ModelContainer** for test isolation
- **MockNotificationService** protocol-based injection
- **XCTest** for UI smoke tests
- All tests are deterministic — no dependency on real notification delivery

## Concurrency Model (Swift 6)

- All `@Observable` ViewModels: `@MainActor`
- All services touching `ModelContext`: `@MainActor`
- `NotificationService`: `@unchecked Sendable` (wraps thread-safe `UNUserNotificationCenter`)
- `NotificationReminderData`: `Sendable` value type bridge
- `RecurrenceRule`, `RecurrenceFrequency`, `LifeCategory`: `Sendable`

## Future Considerations

### Adding Cloud Sync
- Replace local `ModelConfiguration` with CloudKit-backed configuration
- Handle merge conflicts (last-write-wins or user prompt)
- Requires Apple Developer account for CloudKit entitlements

### Adding Widgets
- Create WidgetKit extension
- Share SwiftData container via App Group
- Display today's reminders and upcoming deadlines

### Adding Premium Features
- Implement `PremiumService` with StoreKit 2
- Gate features behind entitlement checks
- Keep core reminder functionality free

### Adding iPad Support
- Change `TARGETED_DEVICE_FAMILY` to `"1,2"` in project.yml
- SwiftUI layouts adapt automatically for most screens
- Consider sidebar navigation for iPad

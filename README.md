# Nudge Life

> Remember what matters. Stay ahead of life.

A privacy-first iOS reminder and life organizer app built with SwiftUI and SwiftData.

## Screenshots

*Launch the app on simulator to see all five tabs: Today, Upcoming, Life, Done, and Settings.*

## Features

### ✅ Implemented (MVP)

- **Today Dashboard** — Greeting, overdue reminders, today's tasks, upcoming life deadlines
- **Upcoming View** — Chronological view with sections: Overdue, Today, Tomorrow, This Week, Later
- **Reminder CRUD** — Create, edit, complete, reopen, reschedule, and delete reminders
- **Recurring Reminders** — Daily, weekly, monthly, yearly with interval support
- **Completion & History** — Complete reminders, view history, reopen or permanently delete
- **Life Organizer** — Track important things by category (Bills, Subscriptions, Documents, Warranties, Appointments, Home, Custom)
- **Life Item CRUD** — Create, edit, archive, unarchive, delete life items
- **Linked Reminders** — Associate reminders with life items
- **Local Notifications** — Schedule, cancel, and reconcile notifications with UNUserNotificationCenter
- **Contextual Permission** — Request notification permission when user first enables notifications, not at launch
- **Notification Reconciliation** — Sync scheduled notifications with data on app foreground
- **Search** — Filter reminders by title in the Upcoming view
- **Swipe Actions** — Complete and delete reminders with swipe gestures
- **Settings** — Notification status, appearance (system/light/dark), privacy info, version
- **Empty States** — Helpful messages when no data exists
- **Accessibility** — Dynamic Type, VoiceOver labels, sufficient contrast, 44pt touch targets
- **Dark Mode** — Full light/dark support following system or user preference
- **Data Persistence** — SwiftData with on-device storage, persists between launches
- **Unit Tests** — 30+ tests covering recurrence rules, services, date logic
- **UI Tests** — Tab navigation and add-item flow verification

### 🔜 Planned (Not Yet Implemented)

- Home-screen widgets (WidgetKit)
- App Intents / Siri integration
- Cloud synchronization (CloudKit or similar)
- File attachments on life items
- Natural-language date entry
- Advanced recurring schedules (custom weekday selection UI)
- Subscription tracking
- Import/export
- Apple Watch app
- Premium subscriptions (StoreKit 2)
- Shared household lists
- Norwegian localization

## Requirements

- **Xcode 16.0+** (built with Xcode 27.0)
- **iOS 18.0+** deployment target
- **Swift 6.0+** (built with Swift 6.4)
- No third-party dependencies

## Getting Started

### 1. Clone the repository

```bash
git clone <repo-url>
cd nudge
```

### 2. Generate the Xcode project

The project uses [XcodeGen](https://github.com/yonaskolb/XcodeGen) to generate `.xcodeproj` from `project.yml`.

```bash
# Install XcodeGen if needed
brew install xcodegen

# Generate the project
xcodegen generate
```

### 3. Open in Xcode

```bash
open NudgeLife.xcodeproj
```

### 4. Build and run

Select an iPhone simulator (iPhone 17 Pro or later recommended) and press ⌘R.

### 5. Run tests

```bash
xcodebuild -project NudgeLife.xcodeproj \
  -scheme NudgeLife \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  test
```

Or in Xcode: ⌘U.

## Permissions

| Permission | When Requested | Required? |
|-----------|---------------|-----------|
| Notifications | When user first enables notification on a reminder | No — app works fully without it |

No other permissions are requested. No network access, no location, no camera, no contacts.

## Architecture

See [ARCHITECTURE.md](ARCHITECTURE.md) for detailed technical documentation.

**Summary:**
- **SwiftUI** + **SwiftData** — native Apple frameworks, no external dependencies
- **Feature-oriented MVVM** — hybrid `@Query` (reactive reads) + `@Observable` ViewModels (writes)
- **Service layer** — `ReminderService`, `LifeItemService`, `NotificationService`
- **DI** — `AppState` container injected via SwiftUI `@Environment`
- **Swift 6 strict concurrency** — `@MainActor` isolation, `Sendable` types for cross-actor data

## Project Structure

```
nudge/
├── project.yml                     # XcodeGen project spec
├── NudgeLife/
│   ├── App/                        # Entry point, ContentView, AppState DI
│   ├── Core/
│   │   ├── Models/                 # SwiftData models + value types
│   │   ├── Services/               # Business logic + notification management
│   │   ├── DesignSystem/           # Theme, colors, typography, reusable components
│   │   └── Extensions/             # Date helpers, View modifiers
│   └── Features/
│       ├── Today/                  # Dashboard
│       ├── Upcoming/               # Chronological list
│       ├── Life/                   # Life organizer
│       ├── Reminders/              # Forms + detail views
│       ├── Completed/              # History
│       ├── Settings/               # App configuration
│       └── Shared/                 # Shared row views, add-item sheet
├── NudgeLifeTests/                 # Unit tests (Swift Testing)
└── NudgeLifeUITests/               # UI tests (XCTest)
```

## Known Limitations

1. **Local-only** — No cloud sync; data exists only on the device
2. **No file attachments** — Data model is prepared but UI not implemented
3. **64-notification limit** — iOS caps scheduled local notifications; supports ~12 concurrent recurring reminders with 5-occurrence buffer
4. **No natural-language date parsing** — Dates are entered via standard DatePicker
5. **iPhone-only** — iPad support is trivial (`TARGETED_DEVICE_FAMILY: "1,2"`) but not yet enabled
6. **No widgets** — WidgetKit integration planned for future release
7. **Premium placeholder** — Settings shows a "coming soon" entry; no StoreKit integration
8. **UI tests are simulator-dependent** — Element timing can vary

## Privacy

Nudge Life is designed to be privacy-first:
- All data is stored locally using SwiftData
- No network requests
- No analytics or tracking
- No account required
- No third-party SDKs
- No sensitive data logging

## License

[To be determined]

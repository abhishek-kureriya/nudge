import Foundation

/// How often a reminder repeats.
enum RecurrenceFrequency: String, Codable, CaseIterable, Sendable {
    case daily
    case weekly
    case monthly
    case yearly

    var displayName: String {
        switch self {
        case .daily: "Daily"
        case .weekly: "Weekly"
        case .monthly: "Monthly"
        case .yearly: "Yearly"
        }
    }
}

/// Describes a repeating schedule for a reminder.
/// Stored as a Codable composite attribute on NudgeReminder.
struct RecurrenceRule: Codable, Equatable, Sendable {
    var frequency: RecurrenceFrequency
    var interval: Int
    var selectedWeekdays: [Int]?  // 1=Sunday..7=Saturday (Calendar weekday numbering)
    var endDate: Date?

    init(frequency: RecurrenceFrequency, interval: Int = 1, selectedWeekdays: [Int]? = nil, endDate: Date? = nil) {
        self.frequency = frequency
        self.interval = max(1, interval)
        self.selectedWeekdays = selectedWeekdays
        self.endDate = endDate
    }

    /// Calculates the next occurrence date after the given date.
    /// Returns nil if the recurrence has ended (past endDate) or no valid next date exists.
    func nextDate(after date: Date, calendar: Calendar = .current) -> Date? {
        let result: Date?

        switch frequency {
        case .daily:
            result = calendar.date(byAdding: .day, value: interval, to: date)

        case .weekly:
            if let weekdays = selectedWeekdays, !weekdays.isEmpty {
                result = nextWeekdayDate(after: date, weekdays: weekdays, calendar: calendar)
            } else {
                result = calendar.date(byAdding: .weekOfYear, value: interval, to: date)
            }

        case .monthly:
            result = nextMonthlyDate(after: date, calendar: calendar)

        case .yearly:
            result = nextYearlyDate(after: date, calendar: calendar)
        }

        // Enforce end date
        if let endDate, let result, result > endDate {
            return nil
        }

        return result
    }

    // MARK: - Private Helpers

    private func nextWeekdayDate(after date: Date, weekdays: [Int], calendar: Calendar) -> Date? {
        let currentWeekday = calendar.component(.weekday, from: date)
        let sortedWeekdays = weekdays.sorted()

        // Find the next weekday in the current week
        if let nextInWeek = sortedWeekdays.first(where: { $0 > currentWeekday }) {
            let daysAhead = nextInWeek - currentWeekday
            return calendar.date(byAdding: .day, value: daysAhead, to: date)
        }

        // Wrap to the first selected weekday in the next interval-week
        guard let firstWeekday = sortedWeekdays.first else { return nil }
        let daysUntilEndOfWeek = 7 - currentWeekday + firstWeekday
        let extraWeeks = (interval - 1) * 7
        return calendar.date(byAdding: .day, value: daysUntilEndOfWeek + extraWeeks, to: date)
    }

    private func nextMonthlyDate(after date: Date, calendar: Calendar) -> Date? {
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        guard let originalDay = components.day else { return nil }

        guard let rawNext = calendar.date(byAdding: .month, value: interval, to: date) else { return nil }

        // Clamp day to the last day of the target month
        let targetComponents = calendar.dateComponents([.year, .month], from: rawNext)
        guard let targetYear = targetComponents.year,
              let targetMonth = targetComponents.month else { return nil }

        let range = calendar.range(of: .day, in: .month, for: rawNext)
        let maxDay = range?.count ?? 28
        let clampedDay = min(originalDay, maxDay)

        var finalComponents = DateComponents()
        finalComponents.year = targetYear
        finalComponents.month = targetMonth
        finalComponents.day = clampedDay
        finalComponents.hour = components.hour
        finalComponents.minute = components.minute
        finalComponents.second = components.second

        return calendar.date(from: finalComponents)
    }

    private func nextYearlyDate(after date: Date, calendar: Calendar) -> Date? {
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        guard let originalYear = components.year,
              let originalMonth = components.month,
              let originalDay = components.day else { return nil }

        let targetYear = originalYear + interval

        // Handle Feb 29 in non-leap years
        var targetDay = originalDay
        if originalMonth == 2 && originalDay == 29 {
            let isLeapYear = calendar.range(of: .day, in: .month,
                for: calendar.date(from: DateComponents(year: targetYear, month: 2, day: 1))!)
            targetDay = min(29, isLeapYear?.count ?? 28)
        }

        var finalComponents = DateComponents()
        finalComponents.year = targetYear
        finalComponents.month = originalMonth
        finalComponents.day = targetDay
        finalComponents.hour = components.hour
        finalComponents.minute = components.minute
        finalComponents.second = components.second

        return calendar.date(from: finalComponents)
    }
}

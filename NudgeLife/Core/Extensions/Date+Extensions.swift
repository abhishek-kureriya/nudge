import Foundation

extension Date {
    // MARK: - Calendar Helpers

    private static var currentCalendar: Calendar { .current }

    var startOfDay: Date {
        Self.currentCalendar.startOfDay(for: self)
    }

    var endOfDay: Date {
        var components = DateComponents()
        components.day = 1
        components.second = -1
        return Self.currentCalendar.date(byAdding: components, to: startOfDay) ?? self
    }

    // MARK: - Relative Checks

    var isToday: Bool {
        Self.currentCalendar.isDateInToday(self)
    }

    var isTomorrow: Bool {
        Self.currentCalendar.isDateInTomorrow(self)
    }

    var isYesterday: Bool {
        Self.currentCalendar.isDateInYesterday(self)
    }

    var isThisWeek: Bool {
        Self.currentCalendar.isDate(self, equalTo: Date(), toGranularity: .weekOfYear)
    }

    var isPast: Bool {
        self < Date()
    }

    /// True if this date's day is before today (ignoring time).
    var isDayBeforeToday: Bool {
        startOfDay < Date().startOfDay
    }

    /// True if this is overdue: the day has passed, or for timed items the moment has passed.
    func isOverdue(isAllDay: Bool) -> Bool {
        if isAllDay {
            return isDayBeforeToday
        }
        return isPast
    }

    // MARK: - Date Arithmetic

    func adding(days: Int, calendar: Calendar = .current) -> Date {
        calendar.date(byAdding: .day, value: days, to: self) ?? self
    }

    func adding(months: Int, calendar: Calendar = .current) -> Date {
        calendar.date(byAdding: .month, value: months, to: self) ?? self
    }

    func adding(years: Int, calendar: Calendar = .current) -> Date {
        calendar.date(byAdding: .year, value: years, to: self) ?? self
    }

    // MARK: - Display

    /// Relative description: "Today", "Tomorrow", "Yesterday", or formatted date.
    var relativeDescription: String {
        if isToday { return "Today" }
        if isTomorrow { return "Tomorrow" }
        if isYesterday { return "Yesterday" }

        let formatter = DateFormatter()
        let calendar = Self.currentCalendar
        if calendar.isDate(self, equalTo: Date(), toGranularity: .year) {
            formatter.dateFormat = "MMM d"
        } else {
            formatter.dateFormat = "MMM d, yyyy"
        }
        return formatter.string(from: self)
    }

    /// Time description: "9:00 AM" format.
    var timeDescription: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter.string(from: self)
    }

    /// Full display: "Today at 9:00 AM" or "Oct 25 at 3:30 PM".
    func displayDescription(isAllDay: Bool) -> String {
        if isAllDay {
            return relativeDescription
        }
        return "\(relativeDescription) at \(timeDescription)"
    }

    // MARK: - Section Grouping

    /// Returns a section key for the Upcoming view grouping.
    enum UpcomingSection: Int, Comparable, CaseIterable {
        case overdue = 0
        case today = 1
        case tomorrow = 2
        case thisWeek = 3
        case later = 4

        var title: String {
            switch self {
            case .overdue: "Overdue"
            case .today: "Today"
            case .tomorrow: "Tomorrow"
            case .thisWeek: "This Week"
            case .later: "Later"
            }
        }

        static func < (lhs: UpcomingSection, rhs: UpcomingSection) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
    }

    func upcomingSection(isAllDay: Bool) -> UpcomingSection {
        if isOverdue(isAllDay: isAllDay) { return .overdue }
        if isToday { return .today }
        if isTomorrow { return .tomorrow }
        if isThisWeek { return .thisWeek }
        return .later
    }
}

import Testing
import Foundation
@testable import NudgeLife

@Suite("RecurrenceRule")
struct RecurrenceRuleTests {

    // MARK: - Daily

    @Test func dailyBasic() {
        let rule = RecurrenceRule(frequency: .daily)
        let start = date(2025, 1, 15, 9, 0)
        let next = rule.nextDate(after: start)
        #expect(next == date(2025, 1, 16, 9, 0))
    }

    @Test func dailyInterval() {
        let rule = RecurrenceRule(frequency: .daily, interval: 3)
        let start = date(2025, 1, 15, 9, 0)
        let next = rule.nextDate(after: start)
        #expect(next == date(2025, 1, 18, 9, 0))
    }

    // MARK: - Weekly

    @Test func weeklyBasic() {
        let rule = RecurrenceRule(frequency: .weekly)
        let start = date(2025, 1, 15, 9, 0) // Wednesday
        let next = rule.nextDate(after: start)
        #expect(next == date(2025, 1, 22, 9, 0))
    }

    @Test func weeklyInterval() {
        let rule = RecurrenceRule(frequency: .weekly, interval: 2)
        let start = date(2025, 1, 15, 9, 0)
        let next = rule.nextDate(after: start)
        #expect(next == date(2025, 1, 29, 9, 0))
    }

    @Test func weeklyWithSelectedWeekdays() {
        // Monday=2, Wednesday=4, Friday=6
        let rule = RecurrenceRule(frequency: .weekly, selectedWeekdays: [2, 4, 6])
        let monday = date(2025, 1, 13, 9, 0) // Monday
        let next = rule.nextDate(after: monday)
        #expect(next == date(2025, 1, 15, 9, 0)) // Wednesday
    }

    @Test func weeklyWithSelectedWeekdaysWrapAround() {
        // Monday=2, Wednesday=4 — start from Friday
        let rule = RecurrenceRule(frequency: .weekly, selectedWeekdays: [2, 4])
        let friday = date(2025, 1, 17, 9, 0) // Friday (weekday=6)
        let next = rule.nextDate(after: friday)
        #expect(next == date(2025, 1, 20, 9, 0)) // Monday
    }

    // MARK: - Monthly

    @Test func monthlyBasic() {
        let rule = RecurrenceRule(frequency: .monthly)
        let start = date(2025, 1, 15, 9, 0)
        let next = rule.nextDate(after: start)
        #expect(next == date(2025, 2, 15, 9, 0))
    }

    @Test func monthlyInterval() {
        let rule = RecurrenceRule(frequency: .monthly, interval: 3)
        let start = date(2025, 1, 15, 9, 0)
        let next = rule.nextDate(after: start)
        #expect(next == date(2025, 4, 15, 9, 0))
    }

    @Test func monthlyEndOfMonthClamping() {
        let rule = RecurrenceRule(frequency: .monthly)
        let start = date(2025, 1, 31, 9, 0)
        let next = rule.nextDate(after: start)
        #expect(next == date(2025, 2, 28, 9, 0))
    }

    @Test func monthlyEndOfMonthClampingLeapYear() {
        let rule = RecurrenceRule(frequency: .monthly)
        let start = date(2024, 1, 31, 9, 0)
        let next = rule.nextDate(after: start)
        #expect(next == date(2024, 2, 29, 9, 0))
    }

    // MARK: - Yearly

    @Test func yearlyBasic() {
        let rule = RecurrenceRule(frequency: .yearly)
        let start = date(2025, 3, 15, 9, 0)
        let next = rule.nextDate(after: start)
        #expect(next == date(2026, 3, 15, 9, 0))
    }

    @Test func yearlyLeapYearFeb29() {
        let rule = RecurrenceRule(frequency: .yearly)
        let start = date(2024, 2, 29, 9, 0)
        let next = rule.nextDate(after: start)
        #expect(next == date(2025, 2, 28, 9, 0))
    }

    @Test func yearlyLeapYearToLeapYear() {
        let rule = RecurrenceRule(frequency: .yearly, interval: 4)
        let start = date(2024, 2, 29, 9, 0)
        let next = rule.nextDate(after: start)
        #expect(next == date(2028, 2, 29, 9, 0))
    }

    // MARK: - End Date

    @Test func endDateRespected() {
        let rule = RecurrenceRule(frequency: .daily, endDate: date(2025, 1, 16, 0, 0))
        let start = date(2025, 1, 15, 9, 0)
        let next = rule.nextDate(after: start)
        #expect(next == nil)
    }

    @Test func endDateAllowsWithin() {
        let rule = RecurrenceRule(frequency: .daily, endDate: date(2025, 1, 17, 0, 0))
        let start = date(2025, 1, 15, 9, 0)
        let next = rule.nextDate(after: start)
        #expect(next == date(2025, 1, 16, 9, 0))
    }

    // MARK: - Interval Clamping

    @Test func intervalClampedToMinimumOne() {
        let rule = RecurrenceRule(frequency: .daily, interval: 0)
        #expect(rule.interval == 1)
    }

    // MARK: - Helpers

    private func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int, _ minute: Int) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone.current
        let components = DateComponents(year: year, month: month, day: day, hour: hour, minute: minute, second: 0)
        return calendar.date(from: components)!
    }
}

import Testing
import Foundation
@testable import NudgeLife

@Suite("Date Extensions")
struct DateExtensionTests {

    @Test func startOfDay() {
        let date = makeDate(2025, 3, 15, 14, 30)
        let start = date.startOfDay
        let components = Calendar.current.dateComponents([.hour, .minute, .second], from: start)
        #expect(components.hour == 0)
        #expect(components.minute == 0)
        #expect(components.second == 0)
    }

    @Test func endOfDay() {
        let date = makeDate(2025, 3, 15, 14, 30)
        let end = date.endOfDay
        let components = Calendar.current.dateComponents([.hour, .minute, .second], from: end)
        #expect(components.hour == 23)
        #expect(components.minute == 59)
        #expect(components.second == 59)
    }

    @Test func isToday() {
        #expect(Date().isToday == true)
        #expect(Date().adding(days: 1).isToday == false)
        #expect(Date().adding(days: -1).isToday == false)
    }

    @Test func isTomorrow() {
        #expect(Date().adding(days: 1).isTomorrow == true)
        #expect(Date().isTomorrow == false)
    }

    @Test func isYesterday() {
        #expect(Date().adding(days: -1).isYesterday == true)
        #expect(Date().isYesterday == false)
    }

    @Test func isDayBeforeToday() {
        #expect(Date().adding(days: -1).isDayBeforeToday == true)
        #expect(Date().isDayBeforeToday == false)
        #expect(Date().adding(days: 1).isDayBeforeToday == false)
    }

    @Test func relativeDescriptionToday() {
        #expect(Date().relativeDescription == "Today")
    }

    @Test func relativeDescriptionTomorrow() {
        #expect(Date().adding(days: 1).relativeDescription == "Tomorrow")
    }

    @Test func relativeDescriptionYesterday() {
        #expect(Date().adding(days: -1).relativeDescription == "Yesterday")
    }

    @Test func addingDays() {
        let date = makeDate(2025, 1, 15, 9, 0)
        let result = date.adding(days: 5)
        let components = Calendar.current.dateComponents([.day], from: result)
        #expect(components.day == 20)
    }

    @Test func upcomingSectionOverdue() {
        let pastDate = Date().adding(days: -2)
        #expect(pastDate.upcomingSection(isAllDay: true) == .overdue)
    }

    @Test func upcomingSectionToday() {
        let laterToday = Calendar.current.date(bySettingHour: 23, minute: 59, second: 0, of: Date())!
        #expect(laterToday.upcomingSection(isAllDay: false) == .today)
    }

    @Test func upcomingSectionLater() {
        let farFuture = Date().adding(days: 30)
        #expect(farFuture.upcomingSection(isAllDay: false) == .later)
    }

    // MARK: - Helpers

    private func makeDate(_ year: Int, _ month: Int, _ day: Int, _ hour: Int, _ minute: Int) -> Date {
        let components = DateComponents(year: year, month: month, day: day, hour: hour, minute: minute, second: 0)
        return Calendar.current.date(from: components)!
    }
}

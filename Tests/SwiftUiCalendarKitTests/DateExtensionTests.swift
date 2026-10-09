// DateExtensionTests.swift
//
// The `Date` and `Calendar` helpers every calendar is built on.

@testable import SwiftUiCalendarKit
import Foundation
import Testing

@Suite("Date helpers — days, weeks and months in the reader's calendar")
struct DateExtensionTests {

    @Test("Midnight is the start of the same day")
    func midnight() {
        #expect(Fixture.at(15, 45).midnight == Fixture.day())
        #expect(Fixture.day().midnight == Fixture.day())
    }

    @Test("The end of a day is one second before the next midnight")
    func endOfDay() {
        let end = Fixture.at(9).endOfDay

        #expect(Fixture.calendar.isDate(end, inSameDayAs: Fixture.day()))
        #expect(end.addingTimeInterval(1) == Fixture.day(1))
    }

    @Test("A day's interval runs from its midnight to its last second")
    func dayInterval() {
        let interval = Fixture.at(9).dayInterval

        #expect(interval.start == Fixture.day())
        #expect(interval.end == Fixture.day().endOfDay)
    }

    @Test("Previous and next date move exactly one calendar day")
    func previousAndNextDate() {
        #expect(Fixture.at(9).previousDate() == Fixture.at(9, day: -1))
        #expect(Fixture.at(9).nextDate() == Fixture.at(9, day: 1))
    }

    @Test("The start of the month is the 1st at midnight")
    func startOfMonth() {
        let start = Fixture.at(9).startOfMonth(in: Fixture.calendar)

        #expect(Fixture.calendar.component(.day, from: start) == 1)
        #expect(Fixture.calendar.isDate(start, equalTo: Fixture.anchor, toGranularity: .month))
        #expect(start == start.midnight)
    }

    @Test("A week is seven consecutive days from the first weekday, containing the date")
    func fetchWeek() {
        let week = Fixture.anchor.fetchWeek(in: Fixture.calendar)

        #expect(week.count == 7)
        #expect(week.contains { Fixture.calendar.isDate($0.date, inSameDayAs: Fixture.anchor) })
        #expect(week.first.map { Fixture.calendar.component(.weekday, from: $0.date) } == Fixture.calendar.firstWeekday)

        for (previous, current) in zip(week, week.dropFirst()) {
            #expect(Fixture.calendar.dateComponents([.day], from: previous.date, to: current.date).day == 1)
        }
    }

    @Test("Only today's entry in a week is flagged as today")
    func fetchWeekMarksToday() {
        let week = Date().fetchWeek(in: Fixture.calendar)

        #expect(week.filter(\.isToday).count == 1)
        let anchorWeekHasToday = Fixture.anchor.fetchWeek(in: Fixture.calendar).contains(where: \.isToday)

        #expect(anchorWeekHasToday == Fixture.anchor.fetchWeekRange(in: Fixture.calendar).contains(Date()))
    }

    @Test("Next and previous weeks follow on directly from the current one")
    func adjacentWeeks() {
        let week = Fixture.anchor.fetchWeek(in: Fixture.calendar)

        guard let first = week.first?.date, let last = week.last?.date else {
            Issue.record("Week was empty")
            return
        }

        #expect(last.createNextWeek(in: Fixture.calendar).first?.date == last.nextDate().midnight)
        #expect(first.createPreviousWeek(in: Fixture.calendar).last?.date == first.previousDate().midnight)
    }

    @Test("The week range runs from the first weekday for seven days")
    func fetchWeekRange() {
        let range = Fixture.anchor.fetchWeekRange(in: Fixture.calendar)

        #expect(range.lowerBound == Fixture.week.first)
        #expect(range.contains(Fixture.at(12)))
        #expect(Fixture.calendar.dateComponents([.day], from: range.lowerBound, to: range.upperBound).day == 7)
    }
}

@Suite("Calendar helpers")
struct CalendarExtensionTests {

    @Test("A day has 24 hours, on the hour, from midnight")
    func hours() {
        let hours = Fixture.calendar.hours

        #expect(hours.count == 24)
        #expect(hours.first == Fixture.calendar.startOfDay(for: Date()))
        #expect(hours.allSatisfy { Fixture.calendar.component(.minute, from: $0) == 0 })
    }

    @Test("Difference in minutes")
    func differenceInMinutes() {
        #expect(Fixture.calendar.differenceInMinutes(start: Fixture.at(9), end: Fixture.at(10, 30)) == 90)
        #expect(Fixture.calendar.differenceInMinutes(start: Fixture.at(10), end: Fixture.at(9)) == -60)
    }

    @Test("Days are generated one per calendar day across an interval")
    func generateDays() {
        let days = Fixture.calendar.generateDays(for: DateInterval(start: Fixture.day(), end: Fixture.day(5)))

        #expect(days == (0..<5).map { Fixture.day($0) })
    }

    @Test("Week of year matches the calendar's own reading")
    func weekOfYear() {
        let expected = Fixture.calendar.component(.weekOfYear, from: Fixture.anchor)

        #expect(Fixture.calendar.weekOfYear(currentDate: Fixture.anchor) == expected)
    }
}

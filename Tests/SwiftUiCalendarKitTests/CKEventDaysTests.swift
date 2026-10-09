// CKEventDaysTests.swift
//
// Which days an event is on. An event that lasts is over *at* its end time, so one that ends on
// the stroke of midnight belongs to the day before, not to both days.

@testable import SwiftUiCalendarKit
import Foundation
import Testing

@Suite("Event days — an event that ends at midnight is over before the next day begins")
struct CKEventDaysTests {

    /// 22:00 on the anchor day until midnight, which is 00:00 the day after.
    private static let lateShow = Fixture.timed(Fixture.at(22), Fixture.day(1), "Late show")

    /// 22:00 until 02:00 the next morning: genuinely on two days.
    private static let overnight = Fixture.timed(Fixture.at(22), Fixture.at(2, day: 1), "Overnight")

    // MARK: Occurs on

    @Test("Ending at midnight, it is on its own day only")
    func endingAtMidnightOccursOnOneDay() {
        #expect(CKUtils.doesEventOccurOnDate(event: Self.lateShow, date: Fixture.day()))
        #expect(!CKUtils.doesEventOccurOnDate(event: Self.lateShow, date: Fixture.day(1)))
    }

    @Test("Running past midnight, it is on both days")
    func crossingMidnightOccursOnBothDays() {
        #expect(CKUtils.doesEventOccurOnDate(event: Self.overnight, date: Fixture.day()))
        #expect(CKUtils.doesEventOccurOnDate(event: Self.overnight, date: Fixture.day(1)))
        #expect(!CKUtils.doesEventOccurOnDate(event: Self.overnight, date: Fixture.day(2)))
    }

    @Test("Starting at midnight, it is on that day and not the one before")
    func startingAtMidnight() {
        let early = Fixture.timed(Fixture.day(), Fixture.at(1))

        #expect(CKUtils.doesEventOccurOnDate(event: early, date: Fixture.day()))
        #expect(!CKUtils.doesEventOccurOnDate(event: early, date: Fixture.day(-1)))
    }

    @Test("A deadline at midnight is on that day")
    func deadlineAtMidnight() {
        let due = Fixture.deadline(Fixture.day(1))

        #expect(CKUtils.doesEventOccurOnDate(event: due, date: Fixture.day(1)))
        #expect(!CKUtils.doesEventOccurOnDate(event: due, date: Fixture.day()))
    }

    @Test("All-day and multi-day events are unchanged: every day they cover, no more")
    func dayKindsUnchanged() {
        let holiday = Fixture.allDay(Fixture.day())
        let trip = Fixture.span(Fixture.day(), Fixture.day(2))

        #expect(CKUtils.doesEventOccurOnDate(event: holiday, date: Fixture.day()))
        #expect(!CKUtils.doesEventOccurOnDate(event: holiday, date: Fixture.day(1)))
        #expect((0...2).allSatisfy { CKUtils.doesEventOccurOnDate(event: trip, date: Fixture.day($0)) })
        #expect(!CKUtils.doesEventOccurOnDate(event: trip, date: Fixture.day(3)))
    }

    @Test("An event that ends before it starts is on its start day and does not trap")
    func inverted() {
        let backwards = Fixture.timed(Fixture.at(10), Fixture.at(9))

        #expect(CKUtils.doesEventOccurOnDate(event: backwards, date: Fixture.day()))
        #expect(!CKUtils.doesEventOccurOnDate(event: backwards, date: Fixture.day(-1)))
    }

    // MARK: Multi-day

    @Test("Ending at midnight is not multi-day; running past it is")
    func multiDay() {
        #expect(!Self.lateShow.isMultiDay(in: Fixture.calendar))
        #expect(Self.overnight.isMultiDay(in: Fixture.calendar))
    }

    // MARK: Where it shows

    @Test("The large month lists it in its own day's cell rather than dropping it")
    func largeMonthShowsIt() {
        let own = CKMonthRowLayout.ownEvents(on: Fixture.day(), events: [Self.lateShow], calendar: Fixture.calendar)

        #expect(own.map(\.id) == [Self.lateShow.id])
        let nextDay = CKMonthRowLayout.ownEvents(
            on: Fixture.day(1),
            events: [Self.lateShow],
            calendar: Fixture.calendar
        )

        #expect(nextDay.isEmpty)
    }

    @Test("The agenda shows it as a one-day event, with its times")
    func agendaTreatsItAsOneDay() {
        let day = CKAgendaDay(id: Fixture.day(), events: [Self.lateShow])

        #expect(day.singleDayEvents(in: Fixture.calendar).map(\.id) == [Self.lateShow.id])
        #expect(day.multiDayEvents(in: Fixture.calendar).isEmpty)
    }

    @Test("The compact month dots only its own day")
    func compactMonthDot() {
        #expect(CKUtils.hasEvents(on: Fixture.day(), in: [Self.lateShow], calendar: Fixture.calendar))
        #expect(!CKUtils.hasEvents(on: Fixture.day(1), in: [Self.lateShow], calendar: Fixture.calendar))
    }
}

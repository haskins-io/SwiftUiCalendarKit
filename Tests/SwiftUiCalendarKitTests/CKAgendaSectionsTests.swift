// CKAgendaSectionsTests.swift
//
// How the agendas group and order their events — `CKAgendaSections` and `CKAgendaDay`.

@testable import SwiftUiCalendarKit
import Foundation
import Testing

@Suite("Agenda sections — each event once, under the right day, in the right order")
struct CKAgendaSectionsTests {

    @Test("No events means no sections")
    func emptyAgenda() {
        #expect(CKAgendaSections.days(events: []).isEmpty)
    }

    @Test("Sections are one per day, earliest first")
    func sectionsAreSortedByDay() {
        let events = [
            Fixture.timed(Fixture.at(9, day: 2), Fixture.at(10, day: 2)),
            Fixture.timed(Fixture.at(9), Fixture.at(10)),
            Fixture.timed(Fixture.at(14), Fixture.at(15)),
            Fixture.deadline(Fixture.at(12, day: 1))
        ]

        let days = CKAgendaSections.days(events: events, calendar: Fixture.calendar)

        #expect(days.map(\.date) == [Fixture.day(0), Fixture.day(1), Fixture.day(2)])
        #expect(days.map(\.events.count) == [2, 1, 1])
    }

    @Test("A multi-day event is listed once, on the day it begins")
    func spanListedOnce() {
        let trip = Fixture.span(Fixture.day(0), Fixture.day(3))

        let days = CKAgendaSections.days(events: [trip], calendar: Fixture.calendar)

        #expect(days.count == 1)
        #expect(days.first?.date == Fixture.day(0))
    }

    @Test("Events that began before `from` are listed under `from`")
    func earlierEventsClampToFrom() {
        let trip = Fixture.span(Fixture.day(-3), Fixture.day(2))
        let lunch = Fixture.timed(Fixture.at(12, day: 1), Fixture.at(13, day: 1))

        let days = CKAgendaSections.days(events: [trip, lunch], from: Fixture.at(8), calendar: Fixture.calendar)

        #expect(days.map(\.date) == [Fixture.day(0), Fixture.day(1)])
        #expect(days.first?.events.map(\.id) == [trip.id])
    }

    @Test("Within a day: all-day and spans, then timed by start, then deadlines")
    func orderWithinADay() {
        let due = Fixture.deadline(Fixture.at(8), "Due")
        let late = Fixture.timed(Fixture.at(15), Fixture.at(16), "Late")
        let early = Fixture.timed(Fixture.at(9), Fixture.at(10), "Early")
        let holiday = Fixture.allDay(Fixture.day(), "Holiday")

        let days = CKAgendaSections.days(events: [due, late, early, holiday], calendar: Fixture.calendar)

        #expect(days.first?.events.map(\.title) == ["Holiday", "Early", "Late", "Due"])
    }

    @Test("A deadline sorts after timed events even when it is earlier in the day")
    func deadlineSortsLast() {
        let due = Fixture.deadline(Fixture.at(7))
        let meeting = Fixture.timed(Fixture.at(16), Fixture.at(17))

        #expect(CKAgendaSections.byLaneThenStart(meeting, due))
        #expect(!CKAgendaSections.byLaneThenStart(due, meeting))
    }

    @Test("A day splits into its multi-day and single-day events")
    func daySplitsBands() {
        let trip = Fixture.span(Fixture.day(0), Fixture.day(2), "Trip")
        let overnight = Fixture.timed(Fixture.at(22), Fixture.at(2, day: 1), "Overnight")
        let lunch = Fixture.timed(Fixture.at(12), Fixture.at(13), "Lunch")
        let due = Fixture.deadline(Fixture.at(17), "Due")

        let day = CKAgendaSections.days(events: [lunch, due, overnight, trip], calendar: Fixture.calendar).first

        #expect(day?.multiDayEvents(in: Fixture.calendar).map(\.title) == ["Trip", "Overnight"])
        #expect(day?.singleDayEvents(in: Fixture.calendar).map(\.title) == ["Lunch", "Due"])
    }

    @Test("Today's section is today's, when there is one")
    func todaysSectionIsToday() {
        let days = CKAgendaSections.days(
            events: [
                Fixture.timed(Fixture.at(9, day: -1), Fixture.at(10, day: -1)),
                Fixture.timed(Fixture.at(9), Fixture.at(10))
            ],
            calendar: Fixture.calendar
        )

        #expect(CKAgendaSections.todaysSection(in: days, today: Fixture.at(15)) == Fixture.day(0))
    }

    @Test("With nothing today, 'Today' lands on the next day that has something")
    func todaysSectionSkipsForward() {
        let days = CKAgendaSections.days(
            events: [
                Fixture.timed(Fixture.at(9, day: -1), Fixture.at(10, day: -1)),
                Fixture.timed(Fixture.at(9, day: 2), Fixture.at(10, day: 2))
            ],
            calendar: Fixture.calendar
        )

        #expect(CKAgendaSections.todaysSection(in: days, today: Fixture.at(15)) == Fixture.day(2))
    }

    @Test("With nothing today or after, there is no section to scroll to")
    func todaysSectionNone() {
        let days = CKAgendaSections.days(
            events: [Fixture.timed(Fixture.at(9, day: -1), Fixture.at(10, day: -1))],
            calendar: Fixture.calendar
        )

        #expect(CKAgendaSections.todaysSection(in: days, today: Fixture.at(15)) == nil)
    }
}

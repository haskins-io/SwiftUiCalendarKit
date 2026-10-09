// CKLayoutTests.swift
//
// Selecting and laying out events for a visible range — `CKLayoutBuilder`, `CKLayout` and the
// `CKUtils` selection helpers they are built on.

@testable import SwiftUiCalendarKit
import Foundation
import Testing

@Suite("Layout builder — every lane, for the range being shown")
struct CKLayoutBuilderTests {

    /// Built once: every `CKEvent` gets a fresh identity, so a computed property would hand
    /// each caller different events.
    private let mixed: [CKEvent] = [
        Fixture.timed(Fixture.at(9), Fixture.at(10), "Today"),
        Fixture.timed(Fixture.at(9, day: 1), Fixture.at(10, day: 1), "Tomorrow"),
        Fixture.allDay(Fixture.day(), "Holiday"),
        Fixture.span(Fixture.day(-1), Fixture.day(1), "Trip"),
        Fixture.deadline(Fixture.at(17), "Due")
    ]

    @Test("An unmeasured view gets an empty layout rather than negative widths")
    func nonPositiveWidthYieldsNothing() async {
        let day = await CKLayoutBuilder.day(date: Fixture.day(), events: self.mixed, width: 0)
        let week = await CKLayoutBuilder.week(date: Fixture.day(), events: self.mixed, width: -50)

        #expect(day.grid.isEmpty && day.bands.isEmpty && day.markers.isEmpty)
        #expect(week.grid.isEmpty && week.bands.isEmpty && week.markers.isEmpty)
    }

    @Test("A day's layout holds only that day's timed events, plus its bands and markers")
    func dayLayout() async {
        let layout = await CKLayoutBuilder.day(date: Fixture.day(), events: self.mixed, width: 300)

        #expect(layout.grid.map(\.event.title) == ["Today"])
        #expect(Set(layout.bands.map(\.title)) == ["Holiday", "Trip"])
        #expect(layout.markers.map(\.title) == ["Due"])
    }

    @Test("A week's layout holds every timed event in the week")
    func weekLayout() async {
        let layout = await CKLayoutBuilder.week(date: Fixture.day(), events: self.mixed, width: 300)
        let weekRange = Fixture.anchor.fetchWeekRange()
        let expected = self.mixed.filter { $0.kind.lane == .grid && weekRange.contains($0.startDate) }

        #expect(Set(layout.grid.map(\.event.id)) == Set(expected.map(\.id)))
    }

    @Test("One layout per page, keyed by the page's midnight")
    func daysLayout() async {
        let dates = [Fixture.at(12, day: -1), Fixture.at(12), Fixture.at(12, day: 1)]

        let layouts = await CKLayoutBuilder.days(dates, events: self.mixed, width: 300)

        #expect(Set(layouts.keys) == [Fixture.day(-1), Fixture.day(0), Fixture.day(1)])
        #expect(layouts[Fixture.day(1)]?.grid.map(\.event.title) == ["Tomorrow"])
    }
}

@Suite("Layout — splitting bands and building per-day chips")
struct CKLayoutTests {

    @Test("Multi-day bands and single-day bands are split apart")
    func bandSplit() {
        let trip = Fixture.span(Fixture.day(), Fixture.day(2), "Trip")
        let holiday = Fixture.allDay(Fixture.day(), "Holiday")
        let layout = CKLayout(bands: [trip, holiday])

        #expect(layout.multiDayBands(in: Fixture.calendar).map(\.title) == ["Trip"])
        #expect(layout.singleDayBands(in: Fixture.calendar).map(\.title) == ["Holiday"])
    }

    @Test("Each day's chips are its one-day all-day events and its deadlines")
    func chipsPerDay() {
        let week = Fixture.week
        let holiday = Fixture.allDay(week[1], "Holiday")
        let fivePM = Fixture.calendar.date(bySettingHour: 17, minute: 0, second: 0, of: week[1]) ?? week[1]
        let due = Fixture.deadline(fivePM, "Due")
        let trip = Fixture.span(week[0], week[3], "Trip")
        let layout = CKLayout(bands: [holiday, trip], markers: [due])

        let chips = layout.chips(for: week, in: Fixture.calendar)

        #expect(chips.count == 7)
        #expect(chips[1].map(\.title) == ["Holiday", "Due"])
        #expect(chips.enumerated().allSatisfy { $0.offset == 1 || $0.element.isEmpty })
    }
}

@Suite("Event selection — which events belong to a day or range")
struct CKEventSelectionTests {

    @Test("A timed event occurs on its own day only")
    func timedOccursOnItsDay() {
        let lunch = Fixture.timed(Fixture.at(12), Fixture.at(13))

        #expect(CKUtils.doesEventOccurOnDate(event: lunch, date: Fixture.day()))
        #expect(CKUtils.doesEventOccurOnDate(event: lunch, date: Fixture.at(23, 30)))
        #expect(!CKUtils.doesEventOccurOnDate(event: lunch, date: Fixture.day(1)))
        #expect(!CKUtils.doesEventOccurOnDate(event: lunch, date: Fixture.day(-1)))
    }

    @Test("A span occurs on every day it covers, and not the day after")
    func spanOccursOnEachDay() {
        let trip = Fixture.span(Fixture.day(), Fixture.day(2))

        #expect((0...2).allSatisfy { CKUtils.doesEventOccurOnDate(event: trip, date: Fixture.day($0)) })
        #expect(!CKUtils.doesEventOccurOnDate(event: trip, date: Fixture.day(3)))
        #expect(!CKUtils.doesEventOccurOnDate(event: trip, date: Fixture.day(-1)))
    }

    @Test("A multi-day event marks every day it covers in the compact month, not just its first")
    func multiDayDots() {
        let trip = [Fixture.span(Fixture.day(-1), Fixture.day(2))]

        #expect((-1...2).allSatisfy { CKUtils.hasEvents(on: Fixture.day($0), in: trip) })
        #expect(!CKUtils.hasEvents(on: Fixture.day(-2), in: trip))
        #expect(!CKUtils.hasEvents(on: Fixture.day(3), in: trip))
    }

    @Test("Each kind of event marks its own day")
    func dotsForEachKind() {
        #expect(CKUtils.hasEvents(on: Fixture.day(), in: [Fixture.timed(Fixture.at(12), Fixture.at(13))]))
        #expect(CKUtils.hasEvents(on: Fixture.day(), in: [Fixture.allDay(Fixture.day())]))
        #expect(CKUtils.hasEvents(on: Fixture.day(), in: [Fixture.deadline(Fixture.at(9))]))
        #expect(!CKUtils.hasEvents(on: Fixture.day(1), in: [Fixture.allDay(Fixture.day())]))
        #expect(!CKUtils.hasEvents(on: Fixture.day(), in: []))
    }

    @Test("A day has a dot exactly when the list under the month has something for it")
    func dotsMatchTheList() {
        let events = [
            Fixture.span(Fixture.day(-1), Fixture.day(2)),
            Fixture.timed(Fixture.at(10, day: 4), Fixture.at(11, day: 4)),
            Fixture.deadline(Fixture.at(9, day: 6))
        ]

        for offset in -3...8 {
            let day = Fixture.day(offset)
            let listed = events.filter { CKUtils.doesEventOccurOnDate(event: $0, date: day) }

            #expect(CKUtils.hasEvents(on: day, in: events) == !listed.isEmpty, "day \(offset)")
        }
    }

    @Test("Bands are ordered by start, the longer first when they start together")
    func bandOrdering() {
        let short = Fixture.span(Fixture.day(), Fixture.day(1), "Short")
        let long = Fixture.span(Fixture.day(), Fixture.day(4), "Long")
        let later = Fixture.allDay(Fixture.day(1), "Later")
        let interval = DateInterval(start: Fixture.day(-1), end: Fixture.day(6))

        let bands = CKUtils.bandEvents(in: interval, events: [later, short, long])

        #expect(bands.map(\.title) == ["Long", "Short", "Later"])
    }

    @Test("Markers outside the range are left out, and the rest come in time order")
    func markerOrdering() {
        let late = Fixture.deadline(Fixture.at(18), "Late")
        let early = Fixture.deadline(Fixture.at(8), "Early")
        let tomorrow = Fixture.deadline(Fixture.at(8, day: 1), "Tomorrow")

        let markers = CKUtils.markerEvents(in: Fixture.day().dayInterval, events: [late, tomorrow, early])

        #expect(markers.map(\.title) == ["Early", "Late"])
    }

    @Test("An event intersects a range it overlaps, touches, or sits inside")
    func intersects() {
        let lunch = Fixture.timed(Fixture.at(12), Fixture.at(13))

        #expect(lunch.intersects(DateInterval(start: Fixture.at(11), end: Fixture.at(12, 30))))
        #expect(lunch.intersects(DateInterval(start: Fixture.at(13), end: Fixture.at(14))))
        #expect(lunch.intersects(DateInterval(start: Fixture.day(), end: Fixture.day(1))))
        #expect(!lunch.intersects(DateInterval(start: Fixture.at(14), end: Fixture.at(15))))
    }
}

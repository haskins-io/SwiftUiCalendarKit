// CKCalendarTests.swift
//
// The calendar the package works in comes from the SwiftUI environment, so it decides where a
// week starts, where a month starts, and which week an event belongs to. These tests hand the
// helpers calendars that disagree with each other, and with the device.

@testable import SwiftUiCalendarKit
import Foundation
import SwiftUI
import Testing

/// Gregorian, starting the week on `firstWeekday` (1 is Sunday, 2 Monday).
private func gregorian(firstWeekday: Int) -> Calendar {
    var calendar = Calendar(identifier: .gregorian)
    calendar.firstWeekday = firstWeekday
    calendar.timeZone = Fixture.calendar.timeZone
    return calendar
}

private func hebrew() -> Calendar {
    var calendar = Calendar(identifier: .hebrew)
    calendar.timeZone = Fixture.calendar.timeZone
    return calendar
}

@Suite("Calendar — weeks and months follow the calendar they are given")
struct CKCalendarTests {

    private let sundayFirst = gregorian(firstWeekday: 1)
    private let mondayFirst = gregorian(firstWeekday: 2)

    // MARK: Weeks

    @Test("A week starts on the calendar's first weekday", arguments: [1, 2, 7])
    func weekStart(firstWeekday: Int) throws {
        let calendar = gregorian(firstWeekday: firstWeekday)
        let week = Fixture.anchor.fetchWeek(in: calendar)

        let first = try #require(week.first)

        #expect(week.count == 7)
        #expect(calendar.component(.weekday, from: first.date) == firstWeekday)
        #expect(week.contains { calendar.isDate($0.date, inSameDayAs: Fixture.anchor) })
    }

    @Test("Next and previous weeks follow the same calendar")
    func adjacentWeeks() throws {
        let week = Fixture.anchor.fetchWeek(in: self.mondayFirst)
        let next = try #require(week.last?.date.createNextWeek(in: self.mondayFirst).first)
        let previous = try #require(week.first?.date.createPreviousWeek(in: self.mondayFirst).first)

        #expect(self.mondayFirst.component(.weekday, from: next.date) == 2)
        #expect(self.mondayFirst.component(.weekday, from: previous.date) == 2)
    }

    @Test("The week range moves with the first weekday")
    func weekRange() {
        let sunday = Fixture.anchor.fetchWeekRange(in: self.sundayFirst)
        let monday = Fixture.anchor.fetchWeekRange(in: self.mondayFirst)

        #expect(self.mondayFirst.dateComponents([.day], from: sunday.lowerBound, to: monday.lowerBound).day == 1)
    }

    @Test("Which week an event is laid out in depends on where the week starts")
    func gridWeek() {
        // Sunday 18 October: the last day of a Monday week, the first of the next Sunday week.
        let sunday = Fixture.timed(Fixture.at(10, day: 4), Fixture.at(11, day: 4))

        let mondayWeek = CKUtils.generateEventViewData(
            date: Fixture.anchor,
            events: [sunday],
            width: 100,
            calendar: self.mondayFirst
        )
        let sundayWeek = CKUtils.generateEventViewData(
            date: Fixture.anchor,
            events: [sunday],
            width: 100,
            calendar: self.sundayFirst
        )

        #expect(mondayWeek.count == 1)
        #expect(sundayWeek.isEmpty)
    }

    @Test("The week view's bands are chosen by the calendar's week")
    func layoutWeek() async {
        // Saturday 10 October: the first day of the Saturday-first week holding the 14th, and
        // the day before the Sunday-first one (11th–17th).
        let saturday = Fixture.allDay(Fixture.day(-4))
        let saturdayFirst = gregorian(firstWeekday: 7)

        let included = await CKLayoutBuilder.week(
            date: Fixture.anchor,
            events: [saturday],
            width: 100,
            calendar: saturdayFirst
        )
        let excluded = await CKLayoutBuilder.week(
            date: Fixture.anchor,
            events: [saturday],
            width: 100,
            calendar: self.sundayFirst
        )

        #expect(included.bands.count == 1)
        #expect(excluded.bands.isEmpty)
    }

    // MARK: Months

    @Test("A Hebrew month starts on its own first day, not the Gregorian 1st")
    func hebrewMonthStart() {
        let hebrew = hebrew()
        let start = Fixture.anchor.startOfMonth(in: hebrew)

        #expect(hebrew.component(.day, from: start) == 1)
        #expect(hebrew.isDate(start, equalTo: Fixture.anchor, toGranularity: .month))
        #expect(start != Fixture.anchor.startOfMonth(in: self.sundayFirst))
    }

    @Test("A Hebrew month grid holds that month, in whole weeks")
    func hebrewMonthGrid() throws {
        let hebrew = hebrew()
        let days = hebrew.monthGridDays(for: Fixture.anchor)
        let inMonth = days.filter { hebrew.isDate($0, equalTo: Fixture.anchor, toGranularity: .month) }

        let first = try #require(inMonth.first)
        let range = try #require(hebrew.range(of: .day, in: .month, for: Fixture.anchor))

        #expect(days.count.isMultiple(of: 7))
        #expect(hebrew.component(.day, from: first) == 1)
        #expect(inMonth.count == range.count)
    }

    @Test("Stepping a month moves one month of the calendar")
    func steppingHebrewMonths() {
        let hebrew = hebrew()
        let moved = CKDateStepper.stepped(Fixture.anchor, by: 1, component: .month, calendar: hebrew)

        let before = hebrew.dateComponents([.month, .day], from: Fixture.anchor)
        let after = hebrew.dateComponents([.month, .day], from: moved)

        #expect(after.day == before.day)
        #expect(after.month != before.month)
    }

    // MARK: Writing dates

    @Test("A date style given a calendar names that calendar's months")
    func formatStyleCalendar() {
        let english = Locale(identifier: "en_GB")
        let gregorianName = Fixture.anchor.formatted(.dateTime.month(.wide).locale(english).calendar(self.sundayFirst))
        let hebrewName = Fixture.anchor.formatted(.dateTime.month(.wide).locale(english).calendar(hebrew()))

        #expect(gregorianName == "October")
        #expect(hebrewName != gregorianName)
    }

    @Test("A date style given a calendar takes its time zone too")
    func formatStyleTimeZone() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(identifier: "Asia/Tokyo"))

        let style = Date.FormatStyle.dateTime.calendar(calendar)

        #expect(style.calendar == calendar)
        #expect(style.timeZone.identifier == "Asia/Tokyo")
    }
}

// MARK: - Views

/// The calendar in the SwiftUI environment reaches every view that shows a date or a week: one
/// drawn with a Sunday-first Gregorian calendar and again with a Monday-first Hebrew one has to
/// come out differently. The machine running the tests is the same for both, so a view still
/// using the device's calendar would draw the same thing twice.
@Suite("Calendar — views follow the environment's calendar, not the device's")
@MainActor
struct CKCalendarEnvironmentTests {

    private static let gregorianCalendar = gregorian(firstWeekday: 1)

    private static let hebrewCalendar: Calendar = {
        var calendar = hebrew()
        calendar.firstWeekday = 2
        return calendar
    }()

    private static func isInk(_ pixel: Bitmap.Pixel) -> Bool {
        pixel.alpha > 60 && pixel.red < 200 && pixel.green < 200 && pixel.blue < 200
    }

    private static let threshold = 0.2

    private static let observer = CKCalendarObserver()
    private static let events = [
        Fixture.timed(Fixture.at(10), Fixture.at(11), "Planning"),
        Fixture.span(Fixture.day(-1), Fixture.day(2), "Trip")
    ]

    /// The views that show a date or lay out a week or month. Views that only show times of day
    /// (the hour labels, event blocks and the current-time line) are the same in every calendar.
    /// `CKAgenda` and `CKCompactAgenda` are left out for the reason given in `CKLocaleTests`.
    private static let views: [(String, AnyView)] = [
        ("day header", AnyView(
            VStack(alignment: .leading) {
                CKDayHeader(currentDate: .constant(Fixture.anchor), width: 600, showTime: false, showDate: true)
            }
            .frame(width: 600, height: 60, alignment: .topLeading)
        )),
        ("calendar header", AnyView(
            CKCalendarHeader(currentDate: .constant(Fixture.anchor), addWeek: false)
                .frame(width: 600)
        )),
        ("week number", AnyView(CKWeekOfYear(date: Fixture.anchor).showWeekNumbers(true).frame(width: 200))),
        ("list: span", AnyView(CKListEventView(event: Self.events[1]).frame(width: 300))),
        ("month", AnyView(
            CKMonth(observer: Self.observer, events: Self.events, date: .constant(Fixture.anchor))
                .frame(width: 700, height: 600)
        )),
        ("compact month", AnyView(
            CKCompactMonth(detail: { _ in EmptyView() }, events: Self.events, date: .constant(Fixture.anchor))
                .frame(width: 390, height: 700)
        )),
        ("timeline day", AnyView(
            CKTimelineDay(observer: Self.observer, events: Self.events, date: .constant(Fixture.anchor))
                .frame(width: 600, height: 600)
        )),
        ("timeline week", AnyView(
            CKTimelineWeek(observer: Self.observer, events: Self.events, date: .constant(Fixture.anchor))
                .frame(width: 800, height: 600)
        )),
        ("compact day", AnyView(
            CKCompactDay(detail: { _ in EmptyView() }, events: Self.events, date: .constant(Fixture.anchor))
                .frame(width: 390, height: 600)
        )),
        ("compact week", AnyView(
            CKCompactWeek(detail: { _ in EmptyView() }, events: Self.events, date: .constant(Fixture.anchor))
                .frame(width: 390, height: 600)
        ))
    ]

    @Test("A view's dates and weeks change with the environment's calendar", arguments: Self.views.map(\.0))
    func followsEnvironment(name: String) throws {
        let view = try #require(Self.views.first { $0.0 == name }?.1)

        let gregorian = try #require(Bitmap.render(view.environment(\.calendar, Self.gregorianCalendar)))
        let hebrew = try #require(Bitmap.render(view.environment(\.calendar, Self.hebrewCalendar)))

        let difference = try #require(gregorian.mismatch(with: hebrew, where: Self.isInk), "nothing drawn")

        #expect(difference > Self.threshold, "\(name) drew the same thing in both calendars")
    }
}

// CalendarStyleTests.swift
//
// The feature-level decisions in `CalendarStyle` — how far a scan reaches, and whether sub-day
// detail is built at all.

@testable import SwiftUiCalendarKit
import Foundation
import Testing

@Suite("Calendar styles — reach and grain")
struct CalendarStyleTests {

    private let calendar = Calendar.current
    private let anchor = Date()

    // MARK: - Scope

    @Test("Only the day view builds sub-day detail")
    func onlyDayScopeIncludesSubEvents() {
        #expect(CalendarStyle.day.scope == .day)

        for style in [CalendarStyle.agenda, .week, .month] {
            #expect(style.scope == .overview, "\(style.displayName) must not carry slots or shots")
        }
    }

    // MARK: - Range

    @Test("Every style covers the day it is anchored on")
    func everyRangeContainsItsAnchor() {
        for style in CalendarStyle.allCases {
            #expect(
                style.range(around: self.anchor).contains(self.anchor),
                "\(style.displayName) must include the date it was asked about"
            )
        }
    }

    @Test("The agenda looks forward, and stops")
    func agendaIsBoundedAndForwardLooking() {
        let range = CalendarStyle.agenda.range(around: self.anchor)

        #expect(range.start == self.anchor.midnight)

        // Bounded, per §6 — never project the whole store.
        #expect(range.duration < 100 * 86_400)
    }

    @Test("The day view reaches its neighbours, because the compact pager pre-renders them")
    func dayRangeCoversAdjacentDays() {
        let range = CalendarStyle.day.range(around: self.anchor)

        let yesterday = self.calendar.date(byAdding: .day, value: -1, to: self.anchor) ?? self.anchor
        let tomorrow = self.calendar.date(byAdding: .day, value: 1, to: self.anchor) ?? self.anchor

        #expect(range.contains(yesterday))
        #expect(range.contains(tomorrow))
    }

    @Test("The week view bleeds past the week, so the columns either side are not blank")
    func weekRangeBleedsPastTheWeek() {
        let week = self.anchor.fetchWeekRange()
        let range = CalendarStyle.week.range(around: self.anchor)

        #expect(range.start < week.lowerBound)
        #expect(range.end > week.upperBound)
    }

    @Test("The month view covers the leading and trailing cells the grid actually draws")
    func monthRangeCoversTheWholeGrid() throws {
        let range = CalendarStyle.month.range(around: self.anchor)
        let month = try #require(self.calendar.dateInterval(of: .month, for: self.anchor))

        // A month grid is six weeks, so the previous month's tail and the next month's head are
        // both on screen. A range stopping at the month boundary leaves them empty.
        #expect(range.start <= self.calendar.date(byAdding: .day, value: -6, to: month.start) ?? month.start)
        #expect(range.end >= self.calendar.date(byAdding: .day, value: 6, to: month.end) ?? month.end)
    }

    @Test("A style survives a round trip through its stored raw value")
    func rawValuesRoundTrip() {
        // `CalendarFeatureView` persists the choice in `@AppStorage` as a raw string, so a
        // renamed case would silently reset every user to the default.
        for style in CalendarStyle.allCases {
            #expect(CalendarStyle(rawValue: style.rawValue) == style)
        }
    }
}

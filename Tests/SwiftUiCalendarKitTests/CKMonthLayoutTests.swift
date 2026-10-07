// CKMonthLayoutTests.swift
//
// The month grid's arithmetic — `CKMonthMetrics`, `CKMonthCellLayout` and `CKMonthRowLayout`.

@testable import SwiftUiCalendarKit
import Foundation
import Testing

@Suite("Month metrics — one set of numbers for the row and the cell")
struct CKMonthMetricsTests {

    @Test("No band rows take no height")
    func zeroBandsHeight() {
        #expect(CKMonthMetrics.bandsHeight(0) == 0)
        #expect(CKMonthMetrics.bandsHeight(-1) == 0)
    }

    @Test("Stacked band rows include the gaps between them, but not after the last")
    func bandsHeightIncludesSpacing() {
        let row = CKMonthMetrics.rowHeight
        let gap = CKMonthMetrics.rowSpacing

        #expect(CKMonthMetrics.bandsHeight(1) == row)
        #expect(CKMonthMetrics.bandsHeight(3) == 3 * row + 2 * gap)
    }

    @Test("A cell too short for any band row holds none, never a negative count")
    func tinyCellHoldsNoBands() {
        #expect(CKMonthMetrics.maxBandRows(cellHeight: 0) == 0)
        #expect(CKMonthMetrics.maxBandRows(cellHeight: 40) == 0)
    }

    @Test("A taller cell holds more band rows, keeping room for the header, notes and one event")
    func maxBandRowsGrowsWithHeight() {
        let fixed = CKMonthMetrics.verticalPadding * 2
            + CKMonthMetrics.headerHeight
            + CKMonthMetrics.notesHeight
            + CKMonthMetrics.rowHeight
        let perRow = CKMonthMetrics.rowHeight + CKMonthMetrics.rowSpacing

        #expect(CKMonthMetrics.maxBandRows(cellHeight: fixed + perRow) == 1)
        #expect(CKMonthMetrics.maxBandRows(cellHeight: fixed + perRow * 3) == 3)
        #expect(CKMonthMetrics.maxBandRows(cellHeight: fixed + perRow * 3 - 1) == 2)
    }

    @Test("The first band sits just under the header")
    func firstBandOffset() {
        #expect(
            CKMonthMetrics.firstBandOffset
            == CKMonthMetrics.verticalPadding + CKMonthMetrics.headerHeight + CKMonthMetrics.rowSpacing
        )
    }
}

@Suite("Month cell — what fits, and what '+ N more' counts")
struct CKMonthCellLayoutTests {

    /// A cell tall enough for exactly `rows` event rows once the header has taken its share.
    private func height(rows: Int) -> CGFloat {
        CKMonthMetrics.headerHeight + CGFloat(rows) * CKMonthMetrics.rowHeight
    }

    private func events(_ count: Int) -> [CKEvent] {
        (0..<count).map { Fixture.timed(Fixture.at(8 + $0), Fixture.at(9 + $0), "E\($0)") }
    }

    @Test("Everything fits: nothing hidden")
    func allFit() {
        let layout = CKMonthCellLayout(
            events: self.events(3),
            reservedBandRows: 0,
            hiddenBands: 0,
            cellHeight: self.height(rows: 3)
        )

        #expect(layout.visible.count == 3)
        #expect(layout.hiddenCount == 0)
    }

    @Test("When some do not fit, one row is kept back for '+ N more'")
    func overflowKeepsARowForTheCount() {
        let layout = CKMonthCellLayout(
            events: self.events(5),
            reservedBandRows: 0,
            hiddenBands: 0,
            cellHeight: self.height(rows: 3)
        )

        #expect(layout.visible.count == 2)
        #expect(layout.hiddenCount == 3)
    }

    @Test("Reserved band rows take space from the day's own events")
    func reservedBandsReduceCapacity() {
        let layout = CKMonthCellLayout(
            events: self.events(3),
            reservedBandRows: 1,
            hiddenBands: 0,
            cellHeight: self.height(rows: 3)
        )

        #expect(layout.visible.count == 1)
        #expect(layout.hiddenCount == 2)
    }

    @Test("Bands the row could not draw are added to the count")
    func hiddenBandsAreCounted() {
        let layout = CKMonthCellLayout(
            events: self.events(1),
            reservedBandRows: 0,
            hiddenBands: 2,
            cellHeight: self.height(rows: 3)
        )

        #expect(layout.visible.count == 1)
        #expect(layout.hiddenCount == 2)
    }

    @Test("A cell with no room shows nothing and counts everything")
    func zeroHeightCell() {
        let layout = CKMonthCellLayout(
            events: self.events(2),
            reservedBandRows: 0,
            hiddenBands: 0,
            cellHeight: 0
        )

        #expect(layout.visible.isEmpty)
        #expect(layout.hiddenCount == 2)
    }

    @Test("Events come before deadlines, each in time order")
    func deadlinesRankLast() {
        let due = Fixture.deadline(Fixture.at(7), "Due")
        let late = Fixture.timed(Fixture.at(15), Fixture.at(16), "Late")
        let early = Fixture.timed(Fixture.at(9), Fixture.at(10), "Early")

        let layout = CKMonthCellLayout(
            events: [due, late, early],
            reservedBandRows: 0,
            hiddenBands: 0,
            cellHeight: self.height(rows: 5)
        )

        #expect(layout.ranked.map(\.title) == ["Early", "Late", "Due"])
    }

    @Test("When it overflows, the deadlines are what is hidden first")
    func overflowHidesDeadlines() {
        let due = Fixture.deadline(Fixture.at(7), "Due")
        let meetings = self.events(2)

        let layout = CKMonthCellLayout(
            events: [due] + meetings,
            reservedBandRows: 0,
            hiddenBands: 0,
            cellHeight: self.height(rows: 2)
        )

        #expect(layout.visible.map(\.title) == ["E0"])
        #expect(!layout.visible.contains { $0.id == due.id })
    }
}

@Suite("Month row — bands capped to what the cells can hold")
struct CKMonthRowLayoutTests {

    private var tallCell: CGFloat { 200 }

    /// Tall enough for exactly one band row.
    private var oneBandCell: CGFloat {
        CKMonthMetrics.verticalPadding * 2
        + CKMonthMetrics.headerHeight
        + CKMonthMetrics.notesHeight
        + CKMonthMetrics.rowHeight
        + CKMonthMetrics.rowHeight + CKMonthMetrics.rowSpacing
    }

    @Test("No bands: nothing drawn, nothing reserved, nothing hidden")
    func noBands() {
        let week = Fixture.week
        let lunch = Fixture.timed(Fixture.at(12), Fixture.at(13))
        let row = CKMonthRowLayout(days: week, events: [lunch], cellHeight: self.tallCell)

        #expect(row.drawn.isEmpty)
        #expect(row.reservedBandRows == Array(repeating: 0, count: week.count))
        #expect(row.hiddenBands == Array(repeating: 0, count: week.count))
    }

    @Test("A band reserves its row only on the days it covers")
    func reservesUnderTheBand() {
        let week = Fixture.week
        let trip = Fixture.span(week[1], week[3])

        let row = CKMonthRowLayout(days: week, events: [trip], cellHeight: self.tallCell)

        #expect(row.drawn.count == 1)
        #expect(row.reservedBandRows == [0, 1, 1, 1, 0, 0, 0])
        #expect(row.hiddenBands.allSatisfy { $0 == 0 })
    }

    @Test("Lanes beyond what the cell can hold are hidden, and counted on the days they cover")
    func deepLanesAreHidden() {
        let week = Fixture.week
        let first = Fixture.span(week[0], week[3], "First")
        let second = Fixture.span(week[2], week[5], "Second")

        let row = CKMonthRowLayout(days: week, events: [first, second], cellHeight: self.oneBandCell)

        #expect(row.drawn.map(\.event.title) == ["First"])
        #expect(row.reservedBandRows == [1, 1, 1, 1, 0, 0, 0])
        #expect(row.hiddenBands == [0, 0, 1, 1, 1, 1, 0])
    }

    @Test("A cell's own events exclude multi-day bands")
    func ownEventsExcludeBands() {
        let trip = Fixture.span(Fixture.day(-1), Fixture.day(1))
        let lunch = Fixture.timed(Fixture.at(12), Fixture.at(13))
        let holiday = Fixture.allDay(Fixture.day())
        let tomorrow = Fixture.timed(Fixture.at(12, day: 1), Fixture.at(13, day: 1))

        let own = CKMonthRowLayout.ownEvents(on: Fixture.day(), events: [trip, lunch, holiday, tomorrow])

        #expect(Set(own.map(\.id)) == [lunch.id, holiday.id])
    }
}

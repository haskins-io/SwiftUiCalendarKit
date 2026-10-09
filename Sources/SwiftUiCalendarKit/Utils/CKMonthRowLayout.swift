//
//  CKMonthRowLayout.swift
//  SwiftUiCalendarKit
//
//  Created by Mark Haskins on 07/10/2026.
//

import Foundation

/// One week row of the month grid: which band runs are drawn, and what each day has to hold
/// clear for them.
///
/// Pulled out of `CKMonth.weekRow` so the capping can be tested without drawing the grid.
nonisolated struct CKMonthRowLayout: Sendable {

    /// The runs the row draws — every run whose lane fits in the cell.
    let drawn: [CKBandRun]

    /// Per column, how many band rows the cell must keep clear. See `CKUtils.bandRowCounts`.
    let reservedBandRows: [Int]

    /// Per column, how many bands were too deep to draw, for the cell's "+ N more".
    let hiddenBands: [Int]

    init(days: [Date], events: [CKEvent], cellHeight: CGFloat, calendar: Calendar = .current) {

        let runs = CKUtils.bandRuns(week: days, events: events, calendar: calendar)

        // Capped here, once, and handed to the cells — see `CKMonthMetrics.maxBandRows`.
        let totalLanes = (runs.map(\.lane).max() ?? -1) + 1
        let laneCount = min(totalLanes, CKMonthMetrics.maxBandRows(cellHeight: cellHeight))

        let drawn = runs.filter { $0.lane < laneCount }

        // Per day, not per row. A cell with no bar over it reserves nothing and starts its own
        // events at the top; the day under a bar still reserves every lane above it, holes
        // included, or the bars stop being level.
        self.drawn = drawn
        self.reservedBandRows = CKUtils.bandRowCounts(runs: drawn, columns: days.count)
        self.hiddenBands = CKUtils.bandCounts(runs: runs.filter { $0.lane >= laneCount }, columns: days.count)
    }

    /// The events a month cell lists itself: those on `day` that are not multi-day bands, which
    /// the row draws instead.
    static func ownEvents(on day: Date, events: [CKEvent], calendar: Calendar = .current) -> [CKEvent] {
        events.filter {
            CKUtils.doesEventOccurOnDate(event: $0, date: day, calendar: calendar) && !$0.isMultiDay(in: calendar)
        }
    }
}

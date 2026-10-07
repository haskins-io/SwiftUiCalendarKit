//
//  CKMonthCellLayout.swift
//  SwiftUiCalendarKit
//
//  Created by Mark Haskins on 07/10/2026.
//

import Foundation

/// Which of a month cell's own events fit, and how many "+ N more" has to account for.
///
/// Pulled out of `CKMonthDayCell` so the arithmetic can be tested without drawing a cell.
nonisolated struct CKMonthCellLayout: Sendable {

    /// The day's own events in display order: what is happening, before what is merely due.
    ///
    /// Multi-day bands are not here — they are laid out for the whole week row and drawn above
    /// the cell, which is what lets a bar keep its height across cells.
    let ranked: [CKEvent]

    /// As many of `ranked` as the cell is tall enough to show.
    let visible: [CKEvent]

    /// The day's events that did not fit, plus the bands the row could not draw.
    let hiddenCount: Int

    /// - Parameters:
    ///   - events: the day's own events — never a multi-day band.
    ///   - reservedBandRows: how many band rows the row asked this cell to keep clear. Taken as
    ///     given: `CKMonth` has already capped it with `CKMonthMetrics.maxBandRows`, and a cell
    ///     that reserved less than the row draws puts a bar through the middle of "+ 1 more".
    ///   - hiddenBands: bands the row could not fit over this day.
    ///   - cellHeight: the height of the whole cell.
    init(events: [CKEvent], reservedBandRows: Int, hiddenBands: Int, cellHeight: CGFloat) {

        let ranked = events.sorted { lhs, rhs in
            Self.rank(lhs) == Self.rank(rhs)
            ? lhs.startDate < rhs.startDate
            : Self.rank(lhs) < Self.rank(rhs)
        }

        let contentHeight = max(0, cellHeight - CKMonthMetrics.headerHeight)
        let used = CKMonthMetrics.bandsHeight(reservedBandRows)

        var capacity = max(0, Int((contentHeight - used) / CKMonthMetrics.rowHeight))

        // Keep a row back for "+ N more" when there is going to be one — otherwise the count
        // itself pushes the last event out.
        if ranked.count > capacity, capacity > 0 {
            capacity -= 1
        }

        let visible = Array(ranked.prefix(capacity))

        self.ranked = ranked
        self.visible = visible
        self.hiddenCount = max(0, events.count - visible.count) + max(0, hiddenBands)
    }

    private static func rank(_ event: CKEvent) -> Int {
        event.kind.lane == .marker ? 1 : 0
    }
}

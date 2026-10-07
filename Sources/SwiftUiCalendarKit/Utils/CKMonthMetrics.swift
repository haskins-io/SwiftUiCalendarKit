//
//  File.swift
//  SwiftUiCalendarKit
//
//  Created by Mark Haskins on 21/09/2026.
//

import Foundation

/// The month grid's vertical arithmetic, in one place.
///
/// `CKMonth` positions the band bars and `CKMonthDayCell` lays out around the space they take,
/// which means two files have to agree exactly on how tall a header is and where the first band
/// row starts. Held apart, those were four magic numbers that would drift the first time either
/// side was adjusted, and the symptom would be a bar sitting a pixel or two off the space
/// reserved for it in every one of forty-two cells.
nonisolated enum CKMonthMetrics {

    /// The row carrying the moon glyph and the date.
    static let headerHeight: CGFloat = 22

    /// One event or one band.
    static let rowHeight: CGFloat = 16

    /// Between stacked rows inside a cell.
    static let rowSpacing: CGFloat = 1

    /// The cell's own horizontal inset. A band cancels it so its wash meets its neighbours.
    static let inset: CGFloat = 3

    /// Above the header and below the last row.
    static let verticalPadding: CGFloat = 2

    /// The golden hour and low water line, when there is one.
    static let notesHeight: CGFloat = 14

    /// Where the first band bar sits, measured from the top of the cell.
    static var firstBandOffset: CGFloat {
        verticalPadding + headerHeight + rowSpacing
    }

    /// How many band rows a cell of this height can hold.
    ///
    /// **The row and the cell must agree on this**, or the row draws a bar into space the cell
    /// did not keep clear — which put a trip straight through "+ 1 more" on every cell of a
    /// busy week. `CKMonth` caps the lanes it draws with this, and the cell reserves exactly what
    /// it is told, so there is one calculation rather than two that can drift.
    ///
    /// Assumes the decoration line is present, which is the conservative reading: a day without
    /// one simply has a row spare.
    static func maxBandRows(cellHeight: CGFloat) -> Int {
        let available = cellHeight - verticalPadding * 2 - headerHeight - notesHeight - rowHeight

        return max(0, Int(available / (rowHeight + rowSpacing)))
    }

    /// How tall `count` stacked band rows are, including the gaps between them.
    static func bandsHeight(_ count: Int) -> CGFloat {
        guard count > 0 else {
            return 0
        }

        return CGFloat(count) * rowHeight + CGFloat(count - 1) * rowSpacing
    }
}

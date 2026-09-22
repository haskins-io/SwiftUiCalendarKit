//
//  File.swift
//  SwiftUiCalendarKit
//
//  Created by Mark Haskins on 21/09/2026.
//

import Foundation

/// An unbroken stretch of one band inside a single week row.
///
/// The month grid can draw a band cell by cell, because each cell only has to agree with its
/// neighbours about *height*. A week row cannot: the bar is wide enough to hold a title, and a
/// title drawn inside the first cell is clipped to that cell however far the wash extends —
/// "CAA OA…" on a bar with six empty columns after it.
///
/// A run is therefore the unit the week draws: one view, `length` columns wide, with the whole
/// run's width to put its title in.
nonisolated struct CKBandRun: Identifiable, Sendable {

    let event: CKEvent

    /// Which row of bars, counting down from the top. Constant for the whole week (see
    /// `CKUtils.bandLanes`), which is what keeps the bars level.
    let lane: Int

    /// Where it begins in the week, as a column index — 0 is the first day of the row.
    let startIndex: Int

    /// How many columns it covers. A band that started before this week begins at 0; one that
    /// ends after it runs to the last column.
    let length: Int

    var id: String {
        "\(self.event.id.recordID)-\(self.lane)-\(self.startIndex)"
    }
}

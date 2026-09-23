//
//  File.swift
//  SwiftUiCalendarKit
//
//  Created by Mark Haskins on 21/09/2026.
//

import Foundation

/// Which of the calendar's three drawing surfaces an event belongs on.
///
/// This is the load-bearing half of `CKEvent.Kind`. Folding the dates into the kind is what
/// makes a zero-height deadline unrepresentable; the lane is what makes sure it is *drawn*
/// somewhere instead of merely being excluded from the grid.
nonisolated enum CKEventLane: Hashable, Sendable {

    /// The hour grid, with overlap columns. `.timed` only.
    case grid

    /// A full-width row above the grid, for things that occupy days rather than hours.
    case band

    /// A pin in the day header — a point in time with consequences and no duration.
    case marker
}

nonisolated extension CKEvent.Kind {

    /// When it begins — what day-bucketing and sorting key on.
    var start: Date {
        switch self {
        case .timed(let start, _):
            start

        case .allDay(let day):
            day.midnight

        case .deadline(let at):
            at

        case .span(let from, _):
            from.midnight
        }
    }

    /// When it ends.
    ///
    /// For `.deadline` this equals `start` — deliberately, so that anything that derives a
    /// duration from it gets zero and is visibly wrong rather than subtly wrong. Nothing should
    /// be deriving one: `CKEventViewData.init` is the only place that does, and it refuses
    /// every kind but `.timed`.
    var end: Date {
        switch self {
        case .timed(_, let end):
            end

        case .allDay(let day):
            day.endOfDay

        case .deadline(let at):
            at

        case .span(_, let through):
            through.endOfDay
        }
    }

    /// Which lane draws it.
    var lane: CKEventLane {
        switch self {
        case .timed:
                .grid

        case .allDay, .span:
                .band

        case .deadline:
                .marker
        }
    }
}

nonisolated extension CKEvent {

    /// When the event begins.
    var startDate: Date { self.kind.start }

    /// When the event ends. See `Kind.end` for why a deadline's equals its start.
    var endDate: Date { self.kind.end }

    var isAllDay: Bool {
        if case .allDay = self.kind {
            return true
        }

        return false
    }

    /// Whether the event covers more than one calendar day, and so wants a band rather than a
    /// row on a single day.
    func isMultiDay(in calendar: Calendar = .current) -> Bool {
        if case .span = self.kind {
            return true
        }

        return !calendar.isDate(self.startDate, inSameDayAs: self.endDate)
    }

    /// Whether any part of the event falls inside `interval`.
    func intersects(_ interval: DateInterval) -> Bool {
        self.startDate <= interval.end && self.endDate >= interval.start
    }
}

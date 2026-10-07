//
//  CKAgendaSections.swift
//  SwiftUiCalendarKit
//
//  Created by Mark Haskins on 07/10/2026.
//

import Foundation

/// How an agenda groups and orders its events. Shared by `CKAgenda` and `CKCompactAgenda`,
/// which used to carry their own copies.
nonisolated enum CKAgendaSections {

    /// The agenda's sections, one per day that has something listed under it, earliest first.
    ///
    /// Each event is listed **once**, on the day it begins — a band belongs on every day it
    /// covers in a grid, but in a list that repeats it down the page. When `from` is given, events
    /// that began before it are listed under `from` instead.
    static func days(
        events: [CKEvent],
        from: Date? = nil,
        calendar: Calendar = .current
    ) -> [CKAgendaDay] {

        let grouped = Dictionary(grouping: events) { Self.bucket(for: $0, from: from, calendar: calendar) }

        return grouped
            .map { date, events in
                CKAgendaDay(id: date, events: events.sorted(by: Self.byLaneThenStart))
            }
            .sorted { $0.date < $1.date }
    }

    /// Which day an event is listed under.
    static func bucket(for event: CKEvent, from: Date?, calendar: Calendar = .current) -> Date {
        let start = calendar.startOfDay(for: event.startDate)

        guard let from else {
            return start
        }

        return max(start, calendar.startOfDay(for: from))
    }

    /// All-day and spanning events first, then the timed ones in order, then the deadlines.
    ///
    /// A deadline sorts last rather than by its time of day on purpose: it is not a slot in the
    /// day's schedule, it is something the day is carrying.
    static func byLaneThenStart(_ lhs: CKEvent, _ rhs: CKEvent) -> Bool {
        let lhsRank = Self.rank(lhs)
        let rhsRank = Self.rank(rhs)

        if lhsRank != rhsRank {
            return lhsRank < rhsRank
        }

        return lhs.startDate < rhs.startDate
    }

    /// The first section on or after `today` — where "Today" lands even when today holds nothing.
    static func todaysSection(in days: [CKAgendaDay], today: Date = Date()) -> Date? {
        let midnight = today.midnight

        return days.first { $0.date >= midnight }?.id
    }

    private static func rank(_ event: CKEvent) -> Int {
        switch event.kind {
        case .allDay, .span:
            0

        case .timed:
            1

        case .deadline:
            2
        }
    }
}

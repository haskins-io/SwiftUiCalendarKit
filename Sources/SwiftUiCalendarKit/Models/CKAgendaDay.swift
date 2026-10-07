//
//  CKAgendaDay.swift
//  SwiftUiCalendarKit
//
//  Created by Mark Haskins on 07/10/2026.
//

import Foundation

/// One section of an agenda list: a day, and the events listed under it.
nonisolated struct CKAgendaDay: Identifiable, Sendable {

    let id: Date

    var date: Date { self.id }

    /// Already in display order — see `CKAgendaSections.byLaneThenStart`.
    let events: [CKEvent]

    /// The events that run across more than one day, earliest first.
    func multiDayEvents(in calendar: Calendar) -> [CKEvent] {
        self.events
            .filter { $0.isMultiDay(in: calendar) }
            .sorted { $0.startDate < $1.startDate }
    }

    /// The events confined to this one day, in display order.
    func singleDayEvents(in calendar: Calendar) -> [CKEvent] {
        self.events.filter { !$0.isMultiDay(in: calendar) }
    }
}

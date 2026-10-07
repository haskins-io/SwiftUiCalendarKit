//
//  File.swift
//  SwiftUiCalendarKit
//
//  Created by Mark Haskins on 23/09/2026.
//

import Foundation

/// Projects a `ModelTwo` onto the calendar — the anchor of the whole view (§2.1).
enum ModelTwoProviding: CKEventProviding {

    static func events(from model: ModelTwo, in range: DateInterval) -> [CKEvent] {
        Self.events(from: model, in: range, calendar: .current)
    }

    static func events(from model: ModelTwo, in range: DateInterval, calendar: Calendar) -> [CKEvent] {

        let start = model.startDate
        let end = max(model.startDate, model.endDate)

        guard start <= range.end, end >= range.start else {
            return []
        }

        return [
            CKEvent(
                kind: Self.kind(start: start, end: end, isAllDay: model.isAllDay, calendar: calendar),
                title: model.title,
                subtitle: "",
                systemImage: "",
                tint: colour,
                isTentative: true
            )
        ]
    }

    private static func kind(start: Date, end: Date, isAllDay: Bool, calendar: Calendar) -> CKEvent.Kind {

        if !calendar.isDate(start, inSameDayAs: end) {
            return .span(from: start, through: end)
        }

        if isAllDay {
            return .allDay(start)
        }

        guard end > start else {
            return .deadline(start)
        }

        return .timed(start: start, end: end)
    }
}

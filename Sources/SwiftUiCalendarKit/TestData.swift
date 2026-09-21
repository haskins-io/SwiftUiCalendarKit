//
//  File.swift
//  SwiftUiCalendarKit
//
//  Created by Mark Haskins on 16/02/2026.
//

#if DEBUG
import SwiftUI

private let calendar = Calendar.current

private let middleDateStart = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: Date()) ?? Date()
private let middleDateEnd = calendar.date(byAdding: .hour, value: 1, to: middleDateStart) ?? Date()

private let midEventStart = calendar.date(byAdding: .day, value: 1, to: middleDateStart) ?? Date()
private let midEventEnd = calendar.date(byAdding: .day, value: 1, to: middleDateEnd) ?? Date()

private func at(hour: Int, minute: Int = 0, on day: Date = midEventStart) -> Date {
    calendar.date(bySettingHour: hour, minute: minute, second: 0, of: day) ?? day
}

private func offset(days: Int, from date: Date) -> Date {
    calendar.date(byAdding: .day, value: days, to: date) ?? date
}

@MainActor
private func preview(
    _ title: String,
    _ kind: CKEvent.Kind,
    systemImage: String = "",
    tint: Color = .ssAccentPrimary,
    tentative: Bool = false
) -> CKEvent {
    CKEvent(
        id: CKEventID(recordID: UUID(), facet: .shoot),
        kind: kind,
        title: title,
        systemImage: systemImage,
        tint: tint,
        source: .booking(UUID()),
        isTentative: tentative
    )
}

/// Preview fixtures, one per kind, so a layout change that only handles `.timed` is visible in
/// the canvas rather than at runtime.
@MainActor let testEvents: [CKEvent] = [

    // Bands
    preview("Multi Day Event", .span(from: offset(days: -1, from: middleDateStart),
                                     through: offset(days: 2, from: middleDateEnd))),
    preview("All Day 1", .allDay(middleDateStart)),
    preview("All Day 2", .allDay(middleDateStart)),

    // Grid — including the overlapping cluster the column algorithm exists for
    preview("Event 2", .timed(start: offset(days: -1, from: middleDateStart),
                              end: offset(days: -1, from: middleDateEnd))),
    preview("Event 3", .timed(start: middleDateStart, end: middleDateEnd)),
    preview("Event 6", .timed(start: midEventStart, end: midEventEnd), tentative: true),
    preview("Event 7", .timed(start: at(hour: 10), end: at(hour: 11))),
    preview("Event 8", .timed(start: at(hour: 10, minute: 30), end: at(hour: 11, minute: 30))),
    preview("Event 12", .timed(start: at(hour: 11), end: at(hour: 12))),
    preview("Event 9", .timed(start: at(hour: 11), end: at(hour: 11, minute: 30))),
    preview("Event 10", .timed(start: at(hour: 15, minute: 15), end: at(hour: 16, minute: 15))),
    preview("Event 11", .timed(start: offset(days: 4, from: middleDateStart),
                               end: offset(days: 4, from: middleDateEnd))),

    // Markers — zero-length, and invisible under the old shape
    preview("Invoice INV-014 due", .deadline(at(hour: 9)), systemImage: "paperplane"),
    preview("Lens service due", .deadline(at(hour: 9, on: offset(days: 2, from: middleDateStart))),
            systemImage: "wrench.and.screwdriver")
]
#endif

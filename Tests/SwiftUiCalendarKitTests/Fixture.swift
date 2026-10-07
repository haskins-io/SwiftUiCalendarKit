// Fixture.swift
//
// Shared builders for the newer suites. Dates are in `Calendar.current`, because most of the
// library reads it directly, and are anchored on a fixed mid-month Wednesday at noon so no test
// depends on what day it runs or lands on a daylight-saving changeover.

@testable import SwiftUiCalendarKit
import Foundation
import SwiftUI

enum Fixture {

    static let calendar = Calendar.current

    /// Wednesday 14 October 2026, midnight.
    static let anchor: Date = {
        calendar.date(from: DateComponents(year: 2026, month: 10, day: 14)) ?? Date()
    }()

    /// Midnight `offset` days from the anchor.
    static func day(_ offset: Int = 0) -> Date {
        calendar.date(byAdding: .day, value: offset, to: anchor)?.midnight ?? anchor
    }

    /// `hour:minute` on the day `dayOffset` days from the anchor.
    static func at(_ hour: Int, _ minute: Int = 0, day dayOffset: Int = 0) -> Date {
        calendar.date(bySettingHour: hour, minute: minute, second: 0, of: day(dayOffset)) ?? day(dayOffset)
    }

    static func event(_ kind: CKEvent.Kind, _ title: String = "Event") -> CKEvent {
        CKEvent(kind: kind, title: title, tint: .blue)
    }

    static func timed(_ start: Date, _ end: Date, _ title: String = "Timed") -> CKEvent {
        event(.timed(start: start, end: end), title)
    }

    static func allDay(_ date: Date, _ title: String = "All day") -> CKEvent {
        event(.allDay(date), title)
    }

    static func span(_ from: Date, _ through: Date, _ title: String = "Span") -> CKEvent {
        event(.span(from: from, through: through), title)
    }

    static func deadline(_ date: Date, _ title: String = "Deadline") -> CKEvent {
        event(.deadline(date), title)
    }

    /// The seven days of the week containing the anchor, starting on the calendar's first weekday.
    static var week: [Date] {
        anchor.fetchWeek().map(\.date)
    }
}

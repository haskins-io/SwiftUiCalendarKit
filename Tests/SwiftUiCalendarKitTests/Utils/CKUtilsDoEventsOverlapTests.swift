//
//  CKUtilsTests.swift
//

import Foundation
import SwiftUI
@testable import SwiftUiCalendarKit // Replace with your actual module name
import Testing

// MARK: - Mock

private struct MockEvent: CKEventSchema {

    var id = UUID()
    var anyHashableID: AnyHashable { AnyHashable(id) }

    var startDate: Date
    var endDate: Date
    var isAllDay: Bool

    var text: String = ""
    var primaryText: String = ""
    var secondaryText: String = ""
    var backgroundColor: String = ""
    var showTotalTime: Bool = false

    func backgroundAsColor() -> Color { .clear }
    func totalTime() -> String { "" }
}

// MARK: - Helpers

extension MockEvent {

    /// Convenience to build dates without typing Calendar boilerplate in every test.
    static func makeDate(hour: Int, minute: Int = 0) -> Date {
        Calendar.current.date(
            bySettingHour: hour,
            minute: minute,
            second: 0,
            of: Date()
        ) ?? Date()
    }
}

// MARK: - Tests

@Suite("CKUtils.doEventsOverlap")
struct CKUtilsDoEventsOverlapTests {

    // MARK: event1 is NOT all-day

    @Test("Returns false when event1 is not all-day, regardless of date ranges")
    func notAllDayReturnsFalse() {
        let event1 = MockEvent(
            startDate: MockEvent.makeDate(hour: 9),
            endDate: MockEvent.makeDate(hour: 10),
            isAllDay: false                          // ← guard condition
        )
        let event2 = MockEvent(
            startDate: MockEvent.makeDate(hour: 9),
            endDate: MockEvent.makeDate(hour: 11),
            isAllDay: true
        )

        #expect(CKUtils.doEventsOverlap(event1, event2) == false)
    }

    // MARK: event1 IS all-day — overlapping ranges

    @Test("Returns true when event1 is all-day and ranges fully overlap")
    func allDayFullOverlapReturnsTrue() {
        let event1 = MockEvent(
            startDate: MockEvent.makeDate(hour: 9),
            endDate: MockEvent.makeDate(hour: 11),
            isAllDay: true
        )
        let event2 = MockEvent(
            startDate: MockEvent.makeDate(hour: 9),
            endDate: MockEvent.makeDate(hour: 11),
            isAllDay: true
        )

        #expect(CKUtils.doEventsOverlap(event1, event2) == true)
    }

    @Test("Returns true when event2 starts inside event1's range")
    func allDayPartialOverlapReturnsTrue() {
        let event1 = MockEvent(
            startDate: MockEvent.makeDate(hour: 9),
            endDate: MockEvent.makeDate(hour: 12),
            isAllDay: true
        )
        let event2 = MockEvent(
            startDate: MockEvent.makeDate(hour: 11),
            endDate: MockEvent.makeDate(hour: 14),
            isAllDay: true
        )

        #expect(CKUtils.doEventsOverlap(event1, event2) == true)
    }

    @Test("Returns true when event2 is entirely contained within event1")
    func allDayContainedOverlapReturnsTrue() {
        let event1 = MockEvent(
            startDate: MockEvent.makeDate(hour: 8),
            endDate: MockEvent.makeDate(hour: 18),
            isAllDay: true
        )
        let event2 = MockEvent(
            startDate: MockEvent.makeDate(hour: 10),
            endDate: MockEvent.makeDate(hour: 12),
            isAllDay: true
        )

        #expect(CKUtils.doEventsOverlap(event1, event2) == true)
    }

    // MARK: event1 IS all-day — non-overlapping ranges

    @Test("Returns false when event2 ends before event1 starts")
    func allDayNoOverlapEvent2BeforeEvent1ReturnsFalse() {
        let event1 = MockEvent(
            startDate: MockEvent.makeDate(hour: 14),
            endDate: MockEvent.makeDate(hour: 16),
            isAllDay: true
        )
        let event2 = MockEvent(
            startDate: MockEvent.makeDate(hour: 9),
            endDate: MockEvent.makeDate(hour: 11),
            isAllDay: true
        )

        #expect(CKUtils.doEventsOverlap(event1, event2) == false)
    }

    @Test("Returns false when event2 starts after event1 ends")
    func allDayNoOverlapEvent2AfterEvent1ReturnsFalse() {
        let event1 = MockEvent(
            startDate: MockEvent.makeDate(hour: 9),
            endDate: MockEvent.makeDate(hour: 11),
            isAllDay: true
        )
        let event2 = MockEvent(
            startDate: MockEvent.makeDate(hour: 14),
            endDate: MockEvent.makeDate(hour: 16),
            isAllDay: true
        )

        #expect(CKUtils.doEventsOverlap(event1, event2) == false)
    }

    // MARK: edge case — shared boundary

    @Test("Returns true when events share only a boundary point (closed ranges touch)")
    func allDaySharedBoundaryReturnsTrue() {
        let boundary = MockEvent.makeDate(hour: 12)

        let event1 = MockEvent(
            startDate: MockEvent.makeDate(hour: 9),
            endDate: boundary,
            isAllDay: true
        )
        let event2 = MockEvent(
            startDate: boundary,
            endDate: MockEvent.makeDate(hour: 15),
            isAllDay: true
        )

        // Closed-range `...` includes both endpoints, so they overlap at the boundary.
        #expect(CKUtils.doEventsOverlap(event1, event2) == true)
    }
}

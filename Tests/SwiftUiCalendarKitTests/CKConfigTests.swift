// CKConfigTests.swift
//
// Small pieces of view logic that live outside the views: working hours, the date stepper, the
// calendar mode labels, and an event's position on the hour grid.

@testable import SwiftUiCalendarKit
import Foundation
import Testing

@Suite("Working hours")
struct CKConfigTests {

    @Test("By default no hour is out of hours")
    func defaultHours() {
        let config = CKConfig()

        #expect((0..<24).allSatisfy { !config.isOutOfHours($0) })
    }

    @Test("Hours before the start and from the end onward are out of hours")
    func workingDay() {
        var config = CKConfig()
        config.dayStart = 9
        config.dayEnd = 17

        #expect(config.isOutOfHours(8))
        #expect(!config.isOutOfHours(9))
        #expect(!config.isOutOfHours(16))
        #expect(config.isOutOfHours(17))
    }
}

@Suite("Date stepper")
struct CKDateStepperTests {

    @Test("Stepping moves by one unit of the stepper's component", arguments: [
        (Calendar.Component.day, 1),
        (.weekOfYear, 7)
    ])
    func stepsByComponent(component: Calendar.Component, days: Int) {
        #expect(CKDateStepper.stepped(Fixture.at(9), by: 1, component: component) == Fixture.at(9, day: days))
        #expect(CKDateStepper.stepped(Fixture.at(9), by: -1, component: component) == Fixture.at(9, day: -days))
    }

    @Test("Stepping by month lands on the same day of the next month")
    func stepsByMonth() {
        let moved = CKDateStepper.stepped(Fixture.at(9), by: 1, component: .month)

        #expect(Fixture.calendar.component(.month, from: moved) == 11)
        #expect(Fixture.calendar.component(.day, from: moved) == 14)
    }

    @Test("Accessibility labels name what one press moves by")
    func labels() {
        #expect(String(localized: CKStrings.previous(.day)) == "Previous day")
        #expect(String(localized: CKStrings.next(.day)) == "Next day")
        #expect(String(localized: CKStrings.previous(.weekOfYear)) == "Previous week")
        #expect(String(localized: CKStrings.next(.weekOfYear)) == "Next week")
        #expect(String(localized: CKStrings.previous(.month)) == "Previous month")
        #expect(String(localized: CKStrings.next(.month)) == "Next month")
    }
}

@Suite("Calendar mode")
struct CKCalendarModeTests {

    @Test("Each mode has a label, in order")
    func labels() {
        #expect(CKCalendarMode.allCases.map { String(localized: $0.label) } == ["Day", "Week", "Month"])
    }
}

@Suite("Event geometry on the hour grid")
struct CKEventViewDataGeometryTests {

    @Test("An event's top is its start time in points from midnight")
    func yOffset() throws {
        let viewData = try #require(
            CKEventViewData(
                event: Fixture.timed(Fixture.at(9, 30), Fixture.at(10)),
                overlapsWith: 1,
                position: 1,
                width: 100
            )
        )

        let expected: CGFloat = 9 * CKTimeline.hourHeight + 30

        #expect(viewData.yOffset == expected)
    }

    @Test("Overlapping events share the column width, less a gap")
    func eventWidth() throws {
        let viewData = try #require(
            CKEventViewData(
                event: Fixture.timed(Fixture.at(9), Fixture.at(10)),
                overlapsWith: 2,
                position: 1,
                width: 100
            )
        )

        #expect(viewData.cellWidth == 100)
        #expect(viewData.eventWidth == 45)
    }
}

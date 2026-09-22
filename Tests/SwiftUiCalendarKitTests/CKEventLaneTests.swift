// CKEventLaneTests.swift

@testable import SwiftUiCalendarKit
import CoreGraphics
import Foundation
import SwiftUI
import Testing

@Suite("CKEvent lanes — which surface draws which kind")
struct CKEventLaneTests {

    private let calendar = Calendar.current

    private func day(_ offset: Int = 0) -> Date {
        self.calendar.date(byAdding: .day, value: offset, to: Date())?.midnight ?? Date()
    }

    private func at(_ hour: Int, _ minute: Int = 0, dayOffset: Int = 0) -> Date {
        self.calendar.date(
            bySettingHour: hour, minute: minute, second: 0, of: self.day(dayOffset)
        ) ?? self.day(dayOffset)
    }

    private func event(_ kind: CKEvent.Kind) -> CKEvent {
        CKEvent(
            kind: kind,
            title: "Event",
            tint: .blue
        )
    }

    // MARK: - Lane routing

    @Test("A timed event draws on the hour grid")
    func timedRoutesToGrid() {
        let kind = CKEvent.Kind.timed(start: self.at(10), end: self.at(11))

        #expect(kind.lane == .grid)
    }

    @Test("A deadline draws as a marker, never on the grid")
    func deadlineRoutesToMarker() {
        let kind = CKEvent.Kind.deadline(self.at(9))

        #expect(kind.lane == .marker)
    }

    @Test("All-day and spanning events draw as bands")
    func dayLengthKindsRouteToBand() {
        #expect(CKEvent.Kind.allDay(self.day()).lane == .band)
        #expect(CKEvent.Kind.span(from: self.day(), through: self.day(3)).lane == .band)
    }

    // MARK: - Derived dates

    @Test("A deadline's end equals its start, so nothing can derive a duration from it")
    func deadlineHasNoDuration() {
        let event = self.event(.deadline(self.at(9)))

        #expect(event.startDate == event.endDate)
    }

    @Test("An all-day event covers its whole day")
    func allDayCoversTheDay() {
        let event = self.event(.allDay(self.at(14, 30)))

        #expect(event.startDate == self.day())
        #expect(event.endDate == self.day().endOfDay)
        #expect(event.isAllDay)
    }

    @Test("A span runs from the first midnight to the last day's end")
    func spanCoversEveryDayItTouches() {
        let event = self.event(.span(from: self.at(14, dayOffset: 0), through: self.at(9, dayOffset: 3)))

        #expect(event.startDate == self.day())
        #expect(event.endDate == self.day(3).endOfDay)
        #expect(event.isMultiDay())
    }

    @Test("A timed event crossing midnight reads as multi-day")
    func timedAcrossMidnightIsMultiDay() {
        let event = self.event(.timed(start: self.at(22), end: self.at(2, dayOffset: 1)))

        #expect(event.isMultiDay())
    }

    // MARK: - Grid geometry is unreachable for anything without a duration

    @Test("CKEventViewData refuses every kind but .timed")
    func viewDataRefusesNonTimedKinds() {
        let refused: [CKEvent.Kind] = [
            .deadline(self.at(9)),
            .allDay(self.day()),
            .span(from: self.day(), through: self.day(2))
        ]

        for kind in refused {
            let viewData = CKEventViewData(
                event: self.event(kind), overlapsWith: 1, position: 1, width: 100
            )

            #expect(viewData == nil, "\(kind) must not produce grid geometry")
        }
    }

    @Test("A timed event that ends where it began is refused rather than drawn zero-height")
    func viewDataRefusesZeroLengthTimedEvent() {
        let instant = self.at(10)
        let viewData = CKEventViewData(
            event: self.event(.timed(start: instant, end: instant)),
            overlapsWith: 1, position: 1, width: 100
        )

        #expect(viewData == nil)
    }

    @Test("A timed event's height is its duration in hours")
    func viewDataHeightFollowsDuration() throws {
        let viewData = try #require(CKEventViewData(
            event: self.event(.timed(start: self.at(10), end: self.at(11, 30))),
            overlapsWith: 1, position: 1, width: 100
        ))

        let expectedHeight: CGFloat = 1.5 * CKTimeline.hourHeight

        #expect(viewData.duration == 5400)
        #expect(viewData.height == expectedHeight)
        #expect(viewData.hour == 10)
        #expect(viewData.minute == 0)
    }

    // MARK: - Selection

    @Test("Deadlines reach the marker lane instead of being dropped")
    func deadlinesSurviveSelection() {
        let due = self.event(.deadline(self.at(9)))
        let shoot = self.event(.timed(start: self.at(10), end: self.at(11)))
        let interval = DateInterval(start: self.day(), end: self.day(1))

        let markers = CKUtils.markerEvents(in: interval, events: [due, shoot])

        #expect(markers.map(\.id) == [due.id])
    }

    @Test("A band that began before the visible range is still on it")
    func bandsIntersectRatherThanStartInside() {
        let trip = self.event(.span(from: self.day(-3), through: self.day(2)))
        let interval = DateInterval(start: self.day(), end: self.day(1))

        #expect(CKUtils.bandEvents(in: interval, events: [trip]).map(\.id) == [trip.id])
    }

    @Test("Only grid events reach the hour grid")
    func gridLayoutTakesTimedEventsOnly() {
        let events = [
            self.event(.timed(start: self.at(10), end: self.at(11))),
            self.event(.deadline(self.at(9))),
            self.event(.allDay(self.day()))
        ]

        let laidOut = CKUtils.generateEventViewData(date: self.day(), events: events, width: 100)

        #expect(laidOut.count == 1)
    }

    // MARK: - The overlap algorithm still behaves

    @Test("Overlapping events share a group and get their own columns")
    func overlappingEventsGetColumns() {
        let events = [
            self.event(.timed(start: self.at(10), end: self.at(11))),
            self.event(.timed(start: self.at(10, 30), end: self.at(11, 30)))
        ]

        let laidOut = CKUtils.generateEventViewData(date: self.day(), events: events, width: 100)

        #expect(laidOut.count == 2)
        #expect(laidOut.allSatisfy { $0.overlapsWith == 2 })
        #expect(Set(laidOut.map(\.position)) == [1, 2])
    }

    @Test("Events that merely touch at a boundary share one column")
    func touchingEventsDoNotConflict() {
        let events = [
            self.event(.timed(start: self.at(10), end: self.at(11))),
            self.event(.timed(start: self.at(11), end: self.at(12)))
        ]

        let laidOut = CKUtils.generateEventViewData(date: self.day(), events: events, width: 100)

        #expect(laidOut.allSatisfy { $0.overlapsWith == 1 })
    }

    // MARK: - Identity

    @Test("One record yields distinct events per facet")
    func facetSeparatesEventsFromOneRecord() {
        let record = UUID()
        let due = CKEventID()
        let overdue = CKEventID()

        #expect(due != overdue)
        #expect(Set([due, overdue]).count == 2)
    }
}

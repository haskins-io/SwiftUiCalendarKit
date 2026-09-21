// CKLayoutBuilderTests.swift

@testable import SwiftUiCalendarKit
import CoreGraphics
import Foundation
import SwiftData
import Testing

@MainActor
@Suite("CKLayoutBuilder — the layout pass and the width it needs")
struct CKLayoutBuilderTests {

    private let context: ModelContext
    private let calendar = Calendar.current

    init() throws {
        self.context = try ViewModelTestSupport.makeContext()
    }

    private func date(_ dayOffset: Int, hour: Int = 12, minute: Int = 0) -> Date {
        let day = self.calendar.date(byAdding: .day, value: dayOffset, to: Date().midnight) ?? Date()
        return self.calendar.date(bySettingHour: hour, minute: minute, second: 0, of: day) ?? day
    }

    /// The reported event: a car journey, 13:00 to 16:30, eleven days out.
    private func seedTravelLeg(dayOffset: Int = 11) {
        let trip = Trip(title: "Bamburgh")
        self.context.insert(trip)

        let leg = TravelLeg(
            mode: .car,
            description: "Car",
            departure: self.date(dayOffset, hour: 13),
            arrival: self.date(dayOffset, hour: 16, minute: 30)
        )
        leg.trip = trip
        self.context.insert(leg)
    }

    private func events(for style: CalendarStyle, around anchor: Date) -> [CKEvent] {
        CKEventAggregator(context: self.context, hasProAccess: true)
            .events(in: style.range(around: anchor), scope: style.scope)
    }

    // MARK: - The projection was never at fault

    @Test("The same timed event reaches every style's range")
    func everyStyleProjectsIt() {
        self.seedTravelLeg()
        let anchor = self.date(11)

        for style in CalendarStyle.allCases {
            let titles = self.events(for: style, around: anchor).map(\.title)

            #expect(titles.contains("Car"), "\(style.displayName) did not project it")
        }
    }

    // MARK: - Width

    @Test("A measured width lays the event out on the grid")
    func positiveWidthProducesGeometry() async throws {
        self.seedTravelLeg()
        let anchor = self.date(11)

        let layout = await CKLayoutBuilder.day(
            date: anchor, events: self.events(for: .day, around: anchor), width: 300
        )

        let drawn = try #require(layout.grid.first)

        // Precomputed, not inlined into the `#expect`. A compound arithmetic expression there
        // can fail while both halves pass on their own — see the note in
        // `CKEventLaneTests.viewDataHeightFollowsDuration`.
        let expectedHeight: CGFloat = 3.5 * CKTimeline.hourHeight

        #expect(layout.grid.count == 1)
        #expect(drawn.hour == 13)
        #expect(drawn.height == expectedHeight)
    }

    @Test("An unmeasured width yields nothing rather than a negative layout")
    func nonPositiveWidthYieldsNothing() async {
        self.seedTravelLeg()
        let anchor = self.date(11)
        let events = self.events(for: .day, around: anchor)

        // This is the behaviour the bug rode in on, and it is still the right one: an event laid
        // out against a zero width gets a negative `eventWidth`. The fix belongs in the views,
        // which must actually measure themselves — see the note at the top of this file.
        for width in [CGFloat(0), -50] {
            let layout = await CKLayoutBuilder.day(date: anchor, events: events, width: width)

            #expect(layout.grid.isEmpty)
            #expect(layout.bands.isEmpty)
            #expect(layout.markers.isEmpty)
        }
    }

    @Test("A week lays out at a measured column width")
    func weekLaysOutAtWidth() async {
        self.seedTravelLeg()
        let anchor = self.date(11)

        let layout = await CKLayoutBuilder.week(
            date: anchor, events: self.events(for: .week, around: anchor), width: 50
        )

        #expect(layout.grid.count == 1)
    }

    // MARK: - The day filter

    @Test("A day's layout holds that day and not its neighbours")
    func dayLayoutIsNarrowedToItsDay() async throws {
        self.seedTravelLeg(dayOffset: 11)
        self.seedTravelLeg(dayOffset: 12)

        let anchor = self.date(11)
        let events = self.events(for: .day, around: anchor)

        // Both are inside the ±1 day range the day style scans, so the narrowing has to happen
        // in the layout — the pager renders its neighbours and each page shows only its own day.
        #expect(events.filter { $0.title == "Car" }.count == 2)

        let layout = await CKLayoutBuilder.day(date: anchor, events: events, width: 300)

        let drawn = try #require(layout.grid.first)

        #expect(layout.grid.count == 1)
        #expect(self.calendar.isDate(drawn.start, inSameDayAs: anchor))
    }
}

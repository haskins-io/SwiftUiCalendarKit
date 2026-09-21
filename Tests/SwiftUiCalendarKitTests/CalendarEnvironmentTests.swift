// CalendarEnvironmentTests.swift

@testable import SwiftUiCalendarKit
import CoreLocation
import Foundation
import SwiftData
import Testing

@MainActor
@Suite("Calendar environment — anchor, ephemeris and optimal windows")
struct CalendarEnvironmentTests {

    private let context: ModelContext
    private let calendar = Calendar.current

    init() throws {
        self.context = try ViewModelTestSupport.makeContext()
    }

    private func location(_ name: String, favourite: Bool = false) -> Location {
        let location = Location(
            name: name, address: "", latitude: 55.6086, longitude: -1.7091, favourite: favourite
        )
        self.context.insert(location)

        return location
    }

    // MARK: - The anchor

    @Test("Choosing an anchor clears the one before it")
    func onlyOneAnchorAtATime() {
        let bamburgh = self.location("Bamburgh")
        let holyIsland = self.location("Holy Island")

        CalendarLocation.choose(bamburgh, context: self.context)
        CalendarLocation.choose(holyIsland, context: self.context)

        #expect(!bamburgh.calendarLocation)
        #expect(holyIsland.calendarLocation)
        #expect(CalendarLocation.current(context: self.context)?.id == holyIsland.id)
    }

    @Test("The anchor is a different choice from the widget's")
    func anchorIsIndependentOfTheWidget() {
        let bamburgh = self.location("Bamburgh")
        let holyIsland = self.location("Holy Island")

        WidgetUtils.changeWidgeLocation(bamburgh, context: self.context)
        CalendarLocation.choose(holyIsland, context: self.context)

        // Both survive. Pinning one to the home screen says nothing about the month you are
        // planning, and the reverse held once and cost a widget pointed at the wrong place.
        #expect(bamburgh.widgetLocation)
        #expect(!bamburgh.calendarLocation)
        #expect(holyIsland.calendarLocation)
        #expect(!holyIsland.widgetLocation)
    }

    @Test("With nothing pinned a favourite stands in")
    func favouriteIsTheFallback() {
        _ = self.location("Alnwick")
        let bamburgh = self.location("Bamburgh", favourite: true)

        // Better than an undecorated grid for someone who has never found the picker — and a
        // favourite is the closest thing to "where I shoot" the app already knows.
        #expect(CalendarLocation.current(context: self.context)?.id == bamburgh.id)
    }

    @Test("With no favourite either, the first saved location stands in")
    func firstLocationIsTheLastResort() {
        let alnwick = self.location("Alnwick")
        _ = self.location("Bamburgh")

        #expect(CalendarLocation.current(context: self.context)?.id == alnwick.id)
    }

    @Test("With no locations at all there is no anchor, and no invented one")
    func noLocationsMeansNoAnchor() {
        #expect(CalendarLocation.current(context: self.context) == nil)
    }

    // MARK: - Decoration

    @Test("A day carries its moon phase and golden hour")
    func decorationCarriesMoonAndGoldenHour() async throws {
        let day = self.calendar.date(from: DateComponents(year: 2026, month: 6, day: 21)) ?? Date()

        let decorations = await CalendarDecorationBuilder.decorations(
            in: day.dayInterval,
            coordinate: CLLocationCoordinate2D(latitude: 55.6086, longitude: -1.7091),
            timeZone: TimeZone(identifier: "Europe/London") ?? .current
        )

        let decoration = try #require(decorations[day.midnight])

        #expect(!decoration.glyph.isEmpty)
        #expect(decoration.notes.contains { $0.systemImage == "sun.horizon.fill" })
    }

    @Test("Without an anchor there is no decoration rather than a guessed one")
    func noCoordinateMeansNoDecoration() async {
        let decorations = await CalendarDecorationBuilder.decorations(
            in: Date().dayInterval,
            coordinate: nil,
            timeZone: .current
        )

        // Sunrise is a question about a place. Falling back to the device's fix, or to
        // Greenwich, would put confident wrong times on a month grid — worse than none.
        #expect(decorations.isEmpty)
    }

    @Test("A month is solved once, for every day it draws")
    func aWholeMonthIsCovered() async {
        let range = CalendarStyle.month.range(around: Date())

        let decorations = await CalendarDecorationBuilder.decorations(
            in: range,
            coordinate: CLLocationCoordinate2D(latitude: 55.6086, longitude: -1.7091),
            timeZone: .current
        )

        // A month grid is six weeks plus the bleed either side. Every cell it can draw has to
        // have been solved, or the far ones read as missing data rather than as a boundary.
        #expect(decorations.count >= 42)
    }

    // MARK: - Optimal windows

    private func window(
        score: Int = 9,
        start: Date,
        type: OptimalWindow.WindowType = .goldenHour
    ) -> OptimalWindow {
        OptimalWindow(
            location: self.location("Bamburgh"),
            windowStart: start,
            windowEnd: start.addingTimeInterval(3_600),
            overallScore: score,
            lightScore: score,
            weatherScore: nil,
            tideScore: nil,
            reasons: ["Clear skies forecast"],
            windowType: type
        )
    }

    private var range: DateInterval {
        DateInterval(start: Date().midnight, end: Date().midnight.addingTimeInterval(10 * 86_400))
    }

    @Test("A scanned window becomes a timed event that can collide with a booking")
    func windowsAreTimedEvents() throws {
        let start = Date().midnight.addingTimeInterval(3 * 86_400 + 19 * 3_600)
        let window = self.window(start: start)

        let event = try #require(OptimalWindowEvents.events(from: window, in: self.range).first)

        // §2.3 filed this under "day decoration", which was the one item in the tier that did
        // not fit: a window has a real start and end, and being an event is what lets the
        // overlap layout show it against the day's commitments.
        #expect(event.kind == .timed(start: start, end: start.addingTimeInterval(3_600)))
        #expect(event.kind.lane == .grid)
        #expect(event.id.facet == .optimal)
    }

    @Test("The ranking survives onto the grid")
    func scoreDrivesTheTint() throws {
        let start = Date().midnight.addingTimeInterval(2 * 86_400)

        let strong = self.window(score: 10, start: start)
        let poor = self.window(score: 4, start: start)

        let best = try #require(OptimalWindowEvents.events(from: strong, in: self.range).first)
        let weak = try #require(OptimalWindowEvents.events(from: poor, in: self.range).first)

        // A 4 and a 10 drawn identically would throw away the ranking the engine worked for.
        #expect(best.tint != weak.tint)
        #expect(!best.isTentative)
        #expect(weak.isTentative)
    }

    @Test("A window outside the visible range is not projected")
    func windowsAreRangeFiltered() {
        let start = Date().midnight.addingTimeInterval(60 * 86_400)

        #expect(OptimalWindowEvents.events(from: self.window(start: start), in: self.range).isEmpty)
    }

    @Test("A window routes to the Optimal Windows screen")
    func windowsRouteBack() throws {
        let start = Date().midnight.addingTimeInterval(86_400)

        let event = try #require(OptimalWindowEvents.events(from: self.window(start: start), in: self.range).first)

        #expect(event.source.destination == .planning(.optimalWindows))
    }

    @Test("Optimal Windows is scoped upstream, so nothing is redacted on the calendar")
    func windowsAreNotRedacted() {
        // CLAUDE.md: scoped, not locked. `OptimalScanScope` bounds the *scan* to three locations
        // over three days for a free user, so their engine simply holds fewer windows. Redacting
        // here would hide a result they can already read on the Optimal Windows screen.
        #expect(!CKEventSource.optimalWindow(UUID()).isProGated)
    }
}

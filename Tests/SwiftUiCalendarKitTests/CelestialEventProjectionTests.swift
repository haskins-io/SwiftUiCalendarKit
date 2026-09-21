// CelestialEventProjectionTests.swift

@testable import SwiftUiCalendarKit
import CoreLocation
import Foundation
import Testing

@Suite("Celestial events — projection")
struct CelestialEventProjectionTests {

    private let bamburgh = CLLocationCoordinate2D(latitude: 55.609, longitude: -1.709)

    private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC") ?? .gmt

        return calendar.date(from: DateComponents(
            timeZone: TimeZone(identifier: "UTC"), year: year, month: month, day: day
        )) ?? Date()
    }

    private func events(_ fromYear: Int, _ toYear: Int) -> [CKEvent] {
        CelestialEvents.events(
            in: DateInterval(start: self.date(fromYear, 1, 1), end: self.date(toYear, 1, 1)),
            coordinate: self.bamburgh,
            timeZone: TimeZone(identifier: "Europe/London") ?? .gmt
        )
    }

    /// **The decision made for a feature that does not exist yet.** A supermoon and a solstice
    /// are instants, but the photograph is not — it is that evening's moonrise, or that day's
    /// golden hour. If either were projected as a bare `.deadline`, the window would have to be
    /// derived again wherever "book around this" is built.
    @Test("Every celestial event carries a real window, not an instant")
    func everyEventCarriesAWindow() {
        let events = self.events(2026, 2029)

        #expect(!events.isEmpty)

        for event in events {
            switch event.kind {
            case .timed(let start, let end):
                #expect(end > start, "\(event.title) has an empty window")

            case .span:
                break

            case .deadline, .allDay:
                Issue.record("\(event.title) was projected without a window")
            }
        }
    }

    /// A solstice's window must be that day's golden hour, and a supermoon's that evening's
    /// moonrise — not the instant of the crossing or of syzygy.
    @Test("The solstice window is the day's light, not the moment of the crossing")
    func theSolsticeWindowIsTheDaysLight() throws {
        let solstice = try #require(
            self.events(2026, 2027).first { $0.id.facet == .solstice }
        )

        // The June solstice crossing is around 08:26 UT; golden hour is in the evening.
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/London") ?? .gmt

        let hour = calendar.component(.hour, from: solstice.startDate)

        #expect(hour > 15, "window began at \(hour):00, which is not the evening light")
        #expect(solstice.endDate > solstice.startDate)
    }

    /// Identity has to survive a recompute, or every row rebuilds and nothing stays selected.
    @Test("Identity is derived from the instant, so it is stable across recomputes")
    func identityIsStableAcrossRecomputes() {
        let first = self.events(2026, 2028)
        let second = self.events(2026, 2028)

        #expect(first.map(\.id) == second.map(\.id))
        #expect(Set(first.map(\.id)).count == first.count, "two events share an id")

        // And the derivation really is a function of the date alone.
        let moment = self.date(2027, 3, 14)

        #expect(CelestialEvents.identity(for: moment) == CelestialEvents.identity(for: moment))
        #expect(CelestialEvents.identity(for: moment) != CelestialEvents.identity(for: moment.addingTimeInterval(1)))
    }

    /// The whole tier is Pro (ROADMAP Pro 5), and the exhaustive `isProGated` switch is what
    /// forced that decision rather than letting a new source default to free.
    @Test("Celestial events are Pro, and redaction names them without giving the detail away")
    func celestialEventsAreProGated() throws {
        let event = try #require(self.events(2026, 2028).first)

        #expect(event.source.isProGated)

        let redacted = event.redacted()

        // Named, not blanked: the existence of an eclipse is the advertisement.
        #expect(redacted.title == "Celestial event")
        #expect(redacted.subtitle == nil)
        #expect(redacted.systemImage == "lock.fill")

        // The tap still routes, so it can land on the paywall.
        #expect(redacted.source == event.source)
    }

    /// Milky Way season keeps its own switch, so a landscape photographer can hold it while an
    /// event shooter turns it off.
    @Test("Layers split the Milky Way season from the rest of the tier")
    func layersSplitTheSeasonFromTheRest() throws {
        let events = self.events(2026, 2027)

        let season = try #require(events.first { $0.id.facet == .milkyWaySeason })
        let other = try #require(events.first { $0.id.facet != .milkyWaySeason })

        #expect(season.layer == .milkyWay)
        #expect(other.layer == .celestial)
    }

    /// **The season must never become a band.** Permit validity windows were removed from this
    /// calendar because a months-long span occupies a row in every cell it crosses and leaves a
    /// grid that can show nothing else; a Milky Way season is longer than most permits and
    /// everybody has one. It is projected as its two boundary nights instead.
    ///
    /// The opposite failure is pinned here too: bucketed by start date, a single `.span` yields
    /// one chip on the day it opens and nothing across the hundred and fifty days it covers.
    @Test("The season is two boundary nights, never a months-long span")
    func theSeasonIsBoundariesNotASpan() throws {
        let seasonEvents = self.events(2026, 2027).filter { $0.id.facet == .milkyWaySeason }

        #expect(!seasonEvents.isEmpty)

        for event in seasonEvents {
            if case .span = event.kind {
                Issue.record("the season was projected as a span, which would consume a band row")
            }

            // A night, not a season.
            #expect(event.endDate.timeIntervalSince(event.startDate) <= 24 * 3_600)
        }

        // Opening and closing are distinguishable, which is the whole point of two events.
        let titles = Set(seasonEvents.map(\.title))

        #expect(titles.contains { $0.contains("opens") })
        #expect(titles.contains { $0.contains("closes") })
    }

    /// **Without an anchor there is nothing local to say**, and §2.3 already settled that
    /// guessing a location is worse than saying nothing — a solar eclipse cannot be placed and a
    /// radiant has no altitude.
    @Test("With no anchor location the whole tier is absent")
    func withNoAnchorTheTierIsAbsent() {
        let events = CelestialEvents.events(
            in: DateInterval(start: self.date(2026, 1, 1), end: self.date(2028, 1, 1)),
            coordinate: nil
        )

        #expect(events.isEmpty)
    }

    /// A solar eclipse below the horizon is omitted rather than listed — there is nothing to see
    /// and nothing to act on. The engine still knows about it; the calendar does not show it.
    @Test("An eclipse with the Sun below the horizon does not reach the calendar")
    func anEclipseBelowTheHorizonIsOmitted() throws {
        let catalogue = try SolarEclipseCatalogue.bundled()

        // Somewhere the 2026 August eclipse is well below the horizon.
        let antipodal = CLLocationCoordinate2D(latitude: -40, longitude: 150)

        let events = CelestialEvents.events(
            in: DateInterval(start: self.date(2026, 8, 1), end: self.date(2026, 9, 1)),
            coordinate: antipodal,
            catalogue: catalogue
        )

        for event in events where event.id.facet == .solarEclipse {
            Issue.record("a solar eclipse was projected with the Sun down")
        }
    }

    /// The requirement that made these events rather than decoration: a day with no bookings on
    /// it still gets a section, because both agendas bucket by grouping events.
    @Test("A celestial event stands on its own day, with nothing else needed")
    func aCelestialEventStandsOnItsOwnDay() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC") ?? .gmt

        let events = self.events(2026, 2027)
        let days = Set(events.map { calendar.startOfDay(for: $0.startDate) })

        // Many distinct days, each of which the agenda will bucket into its own section without
        // any "days that must appear" list threaded through the grouping.
        #expect(days.count > 10)
        #expect(events.allSatisfy { $0.source.isProGated })
    }
}

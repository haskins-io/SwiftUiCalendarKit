// CKEventRedactionTests.swift

@testable import SwiftUiCalendarKit
import Foundation
import SwiftData
import SwiftUI
import Testing

@MainActor
@Suite("Calendar redaction — what a free user sees of a gated feature")
struct CKEventRedactionTests {

    private let context: ModelContext
    private let calendar = Calendar.current

    init() throws {
        self.context = try ViewModelTestSupport.makeContext()
    }

    private var range: DateInterval {
        DateInterval(start: self.date(-30), end: self.date(30))
    }

    private func date(_ dayOffset: Int, hour: Int = 12) -> Date {
        let day = self.calendar.date(byAdding: .day, value: dayOffset, to: Date().midnight) ?? Date()
        return self.calendar.date(bySettingHour: hour, minute: 0, second: 0, of: day) ?? day
    }

    private func inserted<T: PersistentModel>(_ model: T) -> T {
        self.context.insert(model)
        return model
    }

    /// A shoot day with a booking, a call sheet and a named crew member on it.
    private func seedAShootDay() {
        let booking = self.inserted(
            Booking(title: "Coastal Wedding", status: .confirmed,
                    startDate: self.date(3, hour: 9), endDate: self.date(3, hour: 18))
        )

        let sheet = self.inserted(CallSheet(title: "Wedding day", shootDate: self.date(3)))
        sheet.generalCallTime = self.date(3, hour: 7)
        sheet.meetingPoint = "Car park, Bamburgh"
        sheet.booking = booking

        let roster = self.inserted(CrewRoster(title: "Wedding crew", shootDate: self.date(3)))
        let member = self.inserted(CrewMemberBooking(role: .secondShooter, resolvedName: "Grace Hopper"))
        member.confirmationStatus = .confirmed
        member.callTime = self.date(3, hour: 8)
        member.wrapTime = self.date(3, hour: 19)
        member.roster = roster
    }

    private func events(hasProAccess: Bool) -> [CKEvent] {
        CKEventAggregator(context: self.context, hasProAccess: hasProAccess)
            .events(in: self.range, scope: .day)
    }

    // MARK: - Which sources are gated

    @Test("Only the crew and call sheet sources are gated")
    func onlyCrewAndCallSheetsAreGated() {
        #expect(CKEventSource.callSheet(UUID()).isProGated)
        #expect(CKEventSource.crew(UUID()).isProGated)

        let free: [CKEventSource] = [
            .booking(UUID()), .invoice(UUID()), .lead(UUID()), .gearItem(UUID()),
            .permit(UUID()), .trip(UUID()), .studioBooking(UUID()), .shotList(UUID())
        ]

        for source in free {
            #expect(!source.isProGated, "\(source) is not behind a paywall and must not be redacted")
        }
    }

    // MARK: - What a free user sees

    @Test("A free user is told the day is busy, and nothing more")
    func freeUserSeesThatSomethingIsThereButNotWhat() throws {
        self.seedAShootDay()

        let gated = self.events(hasProAccess: false).filter { $0.source.isProGated }

        #expect(gated.count == 2, "the call and the crew member both still occupy the day")

        for event in gated {
            #expect(event.subtitle == nil)
            #expect(event.systemImage == "lock.fill")
        }
    }

    @Test("No crew member's name, role or meeting point reaches a free user")
    func noGatedContentLeaks() {
        self.seedAShootDay()

        let leaked = ["Grace Hopper", "Second Shooter", "Car park, Bamburgh", "Wedding day"]
        let visible = self.events(hasProAccess: false)
            .flatMap { [$0.title, $0.subtitle ?? ""] }

        for secret in leaked {
            #expect(
                !visible.contains { $0.localizedCaseInsensitiveContains(secret) },
                "\"\(secret)\" belongs to a Pro feature and must not appear on a free calendar"
            )
        }
    }

    @Test("Ungated events are untouched for a free user")
    func freeContentIsNotRedacted() throws {
        self.seedAShootDay()

        let booking = try #require(self.events(hasProAccess: false).first { $0.id.facet == .shoot })

        #expect(booking.title == "Coastal Wedding")
    }

    // MARK: - What a subscriber sees

    @Test("A subscriber sees the real thing")
    func subscriberSeesEverything() throws {
        self.seedAShootDay()

        let events = self.events(hasProAccess: true)

        // Both gated facets are `.call`; the roster's carries the member, the sheet's the
        // general call time.
        let gated = events.filter(\.source.isProGated)
        let crew = try #require(gated.first { $0.subtitle == "Second Shooter" })
        let call = try #require(gated.first { $0.subtitle == "Car park, Bamburgh" })

        #expect(crew.title == "Grace Hopper")
        #expect(crew.subtitle == "Second Shooter")
        #expect(call.subtitle == "Car park, Bamburgh")
    }

    // MARK: - The tap still goes somewhere, and somewhere gated

    @Test("A redacted event still routes, so the tap lands on the paywall")
    func redactedEventsStillRoute() {
        self.seedAShootDay()

        let gated = self.events(hasProAccess: false).filter { $0.source.isProGated }

        // `CrewBookingView`, `CrewSplitView`, `CallSheetView` and `CallSheetSplitView` all carry
        // `.proGated`, so routing there is the advert rather than the leak — §6 wants the free
        // calendar to sell the paid one.
        #expect(gated.allSatisfy { $0.source.destination != nil })
        #expect(gated.compactMap(\.source.destination).allSatisfy {
            $0 == .planning(.crewBooking) || $0 == .planning(.shootLogistics)
        })
    }

    @Test("Redaction keeps the shape of the day — a call is still a call, at the same time")
    func redactionPreservesTiming() throws {
        self.seedAShootDay()

        let free = self.events(hasProAccess: false).filter { $0.source.isProGated }
        let paid = self.events(hasProAccess: true).filter { $0.source.isProGated }

        #expect(free.map(\.id) == paid.map(\.id))
        #expect(free.map(\.kind) == paid.map(\.kind))
    }

    @Test("The aggregator defaults to withholding rather than sharing")
    func defaultIsTheSafeDirection() {
        self.seedAShootDay()

        // A call site that forgets the parameter under-shares. The other direction puts a Pro
        // feature's contents on a free screen and nothing errors.
        let defaulted = CKEventAggregator(context: self.context).events(in: self.range, scope: .day)

        #expect(defaulted.filter { $0.source.isProGated }.allSatisfy { $0.subtitle == nil })
    }
}

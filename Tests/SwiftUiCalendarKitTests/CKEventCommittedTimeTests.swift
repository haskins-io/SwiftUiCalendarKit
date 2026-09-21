// CKEventCommittedTimeTests.swift

@testable import SwiftUiCalendarKit
import Foundation
import SwiftData
import Testing

@MainActor
@Suite("Committed time — what can collide with what")
struct CKEventCommittedTimeTests {

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

    private func trip(_ title: String = "Skye") -> Trip {
        self.inserted(Trip(title: title))
    }

    // MARK: - Trips

    @Test("A trip's band comes from its legs and stays, not from stored dates")
    func tripBoundsAreDerived() throws {
        let trip = self.trip()
        let leg = self.inserted(
            TravelLeg(mode: .car, description: "Drive up", departure: self.date(2, hour: 8),
                      arrival: self.date(2, hour: 14))
        )
        leg.trip = trip

        let stay = self.inserted(
            Accommodation(name: "Portree Inn", checkIn: self.date(2, hour: 16), checkOut: self.date(5, hour: 10))
        )
        stay.trip = trip

        let event = try #require(TripEvents.events(from: trip, in: self.range).first)

        #expect(event.kind == .span(from: self.date(2, hour: 8), through: self.date(5, hour: 10)))
        #expect(event.kind.lane == .band)
    }

    @Test("A trip with nothing in it yet has no bounds and projects nothing")
    func emptyTripProjectsNothing() {
        #expect(TripEvents.events(from: self.trip(), in: self.range).isEmpty)
    }

    // MARK: - Travel

    @Test("A travel leg occupies the grid, so a shoot can be seen to clash with it")
    func travelLegIsTimed() throws {
        let leg = self.inserted(
            TravelLeg(mode: .train, description: "London → Inverness",
                      departure: self.date(3, hour: 9), arrival: self.date(3, hour: 17))
        )
        leg.trip = self.trip()

        let event = try #require(TravelLegEvents.events(from: leg, in: self.range).first)

        #expect(event.kind.lane == .grid)
        #expect(event.kind == .timed(start: self.date(3, hour: 9), end: self.date(3, hour: 17)))
    }

    @Test("An overnight leg becomes a band rather than running off the bottom of a column")
    func overnightLegIsABand() throws {
        let leg = self.inserted(
            TravelLeg(mode: .ferry, description: "Overnight crossing",
                      departure: self.date(3, hour: 22), arrival: self.date(4, hour: 7))
        )
        leg.trip = self.trip()

        #expect(try #require(TravelLegEvents.events(from: leg, in: self.range).first).kind.lane == .band)
    }

    @Test("A leg with no trip has nowhere to navigate to, so it is not shown")
    func orphanedLegProjectsNothing() {
        let leg = self.inserted(
            TravelLeg(mode: .car, description: "Drive", departure: self.date(3), arrival: self.date(3, hour: 15))
        )

        #expect(TravelLegEvents.events(from: leg, in: self.range).isEmpty)
    }

    // MARK: - Accommodation

    @Test("A stay is a band, not a block — it is not time the photographer is unavailable")
    func stayIsABand() throws {
        let stay = self.inserted(
            Accommodation(name: "Portree Inn", checkIn: self.date(2, hour: 16), checkOut: self.date(5, hour: 10))
        )
        stay.trip = self.trip()

        let event = try #require(AccommodationEvents.events(from: stay, in: self.range, asOf: self.date(0)).first)

        #expect(event.kind.lane == .band)
        #expect(event.id.facet == .stay)
    }

    @Test("A cancellation deadline is a second event from the same record")
    func stayProducesItsCancellationDeadline() {
        let stay = self.inserted(
            Accommodation(name: "Portree Inn", checkIn: self.date(6, hour: 16), checkOut: self.date(9, hour: 10))
        )
        stay.trip = self.trip()
        stay.isCancellable = true
        stay.cancellationDeadline = self.date(3)

        let events = AccommodationEvents.events(from: stay, in: self.range, asOf: self.date(0))

        #expect(Set(events.map(\.id.facet)) == [.stay, .cancellation])
        #expect(Set(events.map(\.id.recordID)).count == 1)
    }

    @Test("A cancellation deadline already passed is history, not a task")
    func passedCancellationDeadlineIsDropped() {
        let stay = self.inserted(
            Accommodation(name: "Portree Inn", checkIn: self.date(6, hour: 16), checkOut: self.date(9, hour: 10))
        )
        stay.trip = self.trip()
        stay.isCancellable = true
        stay.cancellationDeadline = self.date(-3)

        let events = AccommodationEvents.events(from: stay, in: self.range, asOf: self.date(0))

        #expect(events.allSatisfy { $0.id.facet == .stay })
    }

    // MARK: - Studio

    @Test("A studio hire recombines its separately stored day and time of day")
    func studioHireRecombinesDayAndTime() throws {
        // `startTime` and `endTime` carry whatever day they were created on — here, today —
        // while the hire is next week. Reading them directly would put it on the wrong date.
        let hire = self.inserted(
            StudioBooking(hireDate: self.date(7), startTime: self.date(0, hour: 9), endTime: self.date(0, hour: 17))
        )
        hire.status = .confirmed

        let event = try #require(
            StudioBookingEvents.events(from: hire, in: self.range, asOf: self.date(0), calendar: self.calendar).first
        )

        #expect(event.kind == .timed(start: self.date(7, hour: 9), end: self.date(7, hour: 17)))
    }

    @Test("An enquiry is drawn as tentative; a cancelled hire is not drawn at all")
    func studioStatusDrivesTheDrawing() throws {
        let hire = self.inserted(
            StudioBooking(hireDate: self.date(7), startTime: self.date(0, hour: 9), endTime: self.date(0, hour: 17))
        )
        hire.status = .enquiry

        let event = try #require(
            StudioBookingEvents.events(from: hire, in: self.range, asOf: self.date(0), calendar: self.calendar).first
        )
        #expect(event.isTentative)

        hire.status = .cancelled
        #expect(
            StudioBookingEvents.events(
                from: hire, in: self.range, asOf: self.date(0), calendar: self.calendar
            ).isEmpty
        )
    }

    // MARK: - Crew

    @Test("Each crew member gets their own block, so two call times can be seen to clash")
    func crewIsProjectedPerPerson() {
        let roster = self.inserted(CrewRoster(title: "Wedding crew", shootDate: self.date(4)))

        for name in ["Ada", "Grace"] {
            let member = self.inserted(CrewMemberBooking(role: .photoAssistant, resolvedName: name))
            member.confirmationStatus = .confirmed
            member.callTime = self.date(4, hour: 8)
            member.wrapTime = self.date(4, hour: 18)
            member.roster = roster
        }

        let events = CrewRosterEvents.events(from: roster, in: self.range)

        #expect(events.count == 2)
        #expect(Set(events.map(\.id.recordID)).count == 2)
        #expect(events.allSatisfy { $0.kind.lane == .grid })
    }

    @Test("A call time with no wrap time is a marker, not an invented hour")
    func crewCallWithoutWrapIsAMarker() throws {
        let roster = self.inserted(CrewRoster(title: "Wedding crew", shootDate: self.date(4)))
        let member = self.inserted(CrewMemberBooking(role: .photoAssistant, resolvedName: "Ada"))
        member.confirmationStatus = .pending
        member.callTime = self.date(4, hour: 8)
        member.roster = roster

        let event = try #require(CrewRosterEvents.events(from: roster, in: self.range).first)

        #expect(event.kind == .deadline(self.date(4, hour: 8)))
        #expect(event.isTentative)
    }

    @Test("Declined and cancelled crew are not commitments and cannot clash")
    func declinedCrewIsNotProjected() {
        let roster = self.inserted(CrewRoster(title: "Wedding crew", shootDate: self.date(4)))

        for status in [CrewMemberBooking.ConfirmationStatus.declined, .cancelled] {
            let member = self.inserted(CrewMemberBooking(role: .photoAssistant, resolvedName: "Ada"))
            member.confirmationStatus = status
            member.callTime = self.date(4, hour: 8)
            member.wrapTime = self.date(4, hour: 18)
            member.roster = roster
        }

        #expect(CrewRosterEvents.events(from: roster, in: self.range).isEmpty)
    }

    // MARK: - Scope: what a month grid must not carry

    @Test("A call sheet's general call time shows at every scope")
    func generalCallTimeAlwaysShows() throws {
        let sheet = self.inserted(CallSheet(title: "Wedding", shootDate: self.date(4)))
        sheet.generalCallTime = self.date(4, hour: 7)

        let event = try #require(CallSheetEvents.events(from: sheet, in: self.range, scope: .overview).first)

        #expect(event.id.facet == .call)
        #expect(event.kind.lane == .marker)
    }

    @Test("Slots are built for a day view and never built for an overview")
    func slotsAreDayScopeOnly() {
        let sheet = self.inserted(CallSheet(title: "Wedding", shootDate: self.date(4)))
        let slot = self.inserted(
            CallSheetSlot(slotType: .shoot, title: "Ceremony",
                          startTime: self.date(4, hour: 13), endTime: self.date(4, hour: 14))
        )
        slot.callSheet = sheet

        let overview = CallSheetEvents.events(from: sheet, in: self.range, scope: .overview)
        let day = CallSheetEvents.events(from: sheet, in: self.range, scope: .day)

        #expect(overview.isEmpty)
        #expect(day.map(\.id.facet) == [.slot])
    }

    @Test("Shot target times are day-scope only, and only while the shot is still planned")
    func shotTargetsAreDayScopeOnly() {
        let list = self.inserted(ShotList(title: "Ceremony"))
        let shot = self.inserted(ShotItem(title: "Golden hour portraits"))
        shot.targetTime = self.date(4, hour: 19)
        shot.shotList = list

        #expect(ShotListEvents.events(from: list, in: self.range, scope: .overview).isEmpty)
        #expect(ShotListEvents.events(from: list, in: self.range, scope: .day).count == 1)

        shot.status = .captured
        #expect(ShotListEvents.events(from: list, in: self.range, scope: .day).isEmpty)
    }
}

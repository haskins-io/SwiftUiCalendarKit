// CKEventDeadlineProjectionTests.swift

@testable import SwiftUiCalendarKit
import Foundation
import SwiftData
import SwiftUI
import Testing

@MainActor
@Suite("Deadline projections — the dates that cost money when missed")
struct CKEventDeadlineProjectionTests {

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

    // MARK: - Lead follow-ups (§2.2: "the strongest candidate in the list")

    @Test("A follow-up date the app never surfaces anywhere else becomes a deadline")
    func leadFollowUpIsProjected() throws {
        let lead = self.inserted(Lead(firstName: "Ada", lastName: "Lovelace", stage: .quoted))
        lead.followUpDate = self.date(3)

        let event = try #require(LeadEvents.events(from: lead, in: self.range, asOf: self.date(0)).first)

        #expect(event.kind == .deadline(lead.followUpDate ?? Date()))
        #expect(event.id.facet == .followUp)
        #expect(event.title.contains("Ada Lovelace"))
        #expect(event.source == .lead(lead.id))
    }

    @Test("A lead with no follow-up date set projects nothing")
    func leadWithoutFollowUpProjectsNothing() {
        let lead = self.inserted(Lead(firstName: "Ada", lastName: "Lovelace"))

        #expect(LeadEvents.events(from: lead, in: self.range, asOf: self.date(0)).isEmpty)
    }

    @Test("A won or lost lead has stopped needing chasing")
    func settledLeadsProjectNothing() {
        for stage in [Lead.Stage.won, .lost] {
            let lead = self.inserted(Lead(firstName: "Ada", lastName: "Lovelace", stage: stage))
            lead.followUpDate = self.date(3)

            #expect(
                LeadEvents.events(from: lead, in: self.range, asOf: self.date(0)).isEmpty,
                "a \(stage.displayName) lead should not be chased"
            )
        }
    }

    @Test("A follow-up already missed is tinted as overdue rather than dropped")
    func missedFollowUpIsStillShown() throws {
        let lead = self.inserted(Lead(firstName: "Ada", lastName: "Lovelace", stage: .quoted))
        lead.followUpDate = self.date(-4)

        let event = try #require(LeadEvents.events(from: lead, in: self.range, asOf: self.date(0)).first)

        #expect(event.tint == .red)
    }

    // MARK: - Gear

    @Test("A service record's date wins over the item's own")
    func serviceRecordDateIsPreferred() throws {
        let item = self.inserted(GearItem(name: "24-70mm"))
        item.nextServiceDue = self.date(20)

        let record = self.inserted(
            ServiceRecord(serviceDate: self.date(-100), serviceType: .generalService, description: "Clean")
        )
        record.nextServiceDue = self.date(6)
        record.gearItem = item

        let events = GearItemEvents.events(from: item, in: self.range, asOf: self.date(0))
        let service = try #require(events.first { $0.id.facet == .serviceDue })

        #expect(service.kind == .deadline(self.date(6)))
    }

    @Test("Without a service record the item's own date is used")
    func itemDateIsTheFallback() throws {
        let item = self.inserted(GearItem(name: "24-70mm"))
        item.nextServiceDue = self.date(6)

        let events = GearItemEvents.events(from: item, in: self.range, asOf: self.date(0))

        #expect(try #require(events.first).kind == .deadline(self.date(6)))
    }

    @Test("A hire return is projected only while the item is actually on hire")
    func hireReturnNeedsAHire() throws {
        let item = self.inserted(GearItem(name: "600mm"))
        item.hireReturnDate = self.date(4)

        #expect(GearItemEvents.events(from: item, in: self.range, asOf: self.date(0)).isEmpty)

        item.isHired = true
        let events = GearItemEvents.events(from: item, in: self.range, asOf: self.date(0))

        #expect(try #require(events.first).id.facet == .hireReturn)
    }

    @Test("One gear item can produce both of its dates at once")
    func gearItemProducesTwoEvents() {
        let item = self.inserted(GearItem(name: "600mm"))
        item.isHired = true
        item.hireReturnDate = self.date(4)
        item.nextServiceDue = self.date(9)

        let events = GearItemEvents.events(from: item, in: self.range, asOf: self.date(0))

        #expect(events.count == 2)
        #expect(Set(events.map(\.id.facet)) == [.serviceDue, .hireReturn])
        #expect(Set(events.map(\.id.recordID)) == [item.id])
    }

    // MARK: - Permits — four date fields, three meanings

    @Test("A permit's validity window is not drawn — only its expiry is")
    func permitValidityIsNotABand() throws {
        let permit = self.inserted(Permit(title: "Beach access"))
        permit.applicationStatus = .granted
        permit.validFrom = self.date(-2)
        permit.validUntil = self.date(10)

        let events = PermitEvents.events(from: permit, in: self.range, asOf: self.date(0))

        // Reversing §2.2, which filed the window as "arguably Tier 1 as a band". It is a band,
        // and that is the problem: a permit valid for a year occupies every cell of every month
        // for its whole life. Two of them already took half the rows of every day in September.
        // The expiry is the part that asks something of the photographer, and it survives.
        #expect(events.allSatisfy { $0.kind.lane != .band })

        let expiry = try #require(events.first { $0.id.facet == .expiry })
        #expect(expiry.kind == .deadline(self.date(10)))
    }

    @Test("A decision date is projected only while the decision is outstanding")
    func decisionIsChasedOnlyWhileAwaited() throws {
        let permit = self.inserted(Permit(title: "Drone flight"))
        permit.applicationStatus = .applied
        permit.applicationDate = self.date(-10)
        permit.decisionDate = self.date(5)

        let awaiting = PermitEvents.events(from: permit, in: self.range, asOf: self.date(0))
        #expect(try #require(awaiting.first).id.facet == .decision)

        permit.applicationStatus = .granted
        let decided = PermitEvents.events(from: permit, in: self.range, asOf: self.date(0))
        #expect(decided.allSatisfy { $0.id.facet != .decision })
    }

    @Test("A refused, cancelled or unnecessary permit has no dates worth watching")
    func settledPermitsProjectNothing() {
        for status in [PermitApplicationStatus.refused, .cancelled, .notRequired] {
            let permit = self.inserted(Permit(title: "Beach access"))
            permit.applicationStatus = status
            permit.validFrom = self.date(-2)
            permit.validUntil = self.date(10)

            #expect(
                PermitEvents.events(from: permit, in: self.range, asOf: self.date(0)).isEmpty,
                "\(status.displayName) should project nothing"
            )
        }
    }

    // MARK: - The synthetic contract alert (§2.2 — derived, not stored)

    @Test("A booking approaching with a contract still unsigned raises an alert")
    func unsignedContractRaisesAnAlert() throws {
        let booking = self.inserted(
            Booking(title: "Coastal Wedding", startDate: self.date(10), endDate: self.date(10, hour: 18))
        )
        let contract = self.inserted(Contract(templateName: "Standard", status: .sent))
        contract.sentAt = self.date(-5)
        contract.booking = booking

        let event = try #require(ContractEvents.events(from: booking, in: self.range).first)

        #expect(event.id.facet == .unsigned)
        #expect(event.id.recordID == contract.id)

        // Fires five days before the shoot, and routes to the booking rather than the contract:
        // opening the booking is what the photographer needs to do about it.
        #expect(event.kind == .deadline(self.date(10 - ContractEvents.warningWindow)))
        #expect(event.source == .booking(booking.id))
    }

    @Test("A signed, draft or cancelled contract raises nothing")
    func settledContractsRaiseNothing() {
        for status in [ContractStatus.signed, .draft, .cancelled] {
            let booking = self.inserted(
                Booking(title: "Coastal Wedding", startDate: self.date(10), endDate: self.date(10, hour: 18))
            )
            let contract = self.inserted(Contract(templateName: "Standard", status: status))
            contract.booking = booking

            #expect(
                ContractEvents.events(from: booking, in: self.range).isEmpty,
                "a \(status.rawValue) contract should raise nothing"
            )
        }
    }

    @Test("A booking with no contract at all raises nothing")
    func noContractRaisesNothing() {
        let booking = self.inserted(
            Booking(title: "Coastal Wedding", startDate: self.date(10), endDate: self.date(10, hour: 18))
        )

        #expect(ContractEvents.events(from: booking, in: self.range).isEmpty)
    }
}

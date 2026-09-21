// CKEventAggregatorTests.swift
//

@testable import SwiftUiCalendarKit
import Foundation
import SwiftData
import Testing

@MainActor
@Suite("Calendar aggregation — a visible range, and nothing beyond it")
struct CKEventAggregatorTests {

    private let context: ModelContext
    private let calendar = Calendar.current

    init() throws {
        self.context = try ViewModelTestSupport.makeContext()
    }

    private func date(_ dayOffset: Int, hour: Int = 12) -> Date {
        let day = self.calendar.date(byAdding: .day, value: dayOffset, to: Date().midnight) ?? Date()
        return self.calendar.date(bySettingHour: hour, minute: 0, second: 0, of: day) ?? day
    }

    private func inserted<T: PersistentModel>(_ model: T) -> T {
        self.context.insert(model)
        return model
    }

    private var aggregator: CKEventAggregator {
        CKEventAggregator(context: self.context)
    }

    /// A shoot, an invoice, a lead follow-up and a hire return — four modules, one week.
    private func seedAWeek() {
        let booking = self.inserted(
            Booking(title: "Coastal Wedding", status: .confirmed,
                    startDate: self.date(3, hour: 9), endDate: self.date(3, hour: 18))
        )

        let invoice = self.inserted(
            Invoice(invoiceNumber: "INV-001", invoiceType: .full, amount: 500,
                    taxRate: 20, issueDate: self.date(-10), dueDate: self.date(4))
        )
        invoice.invoiceStatus = .sent
        invoice.booking = booking

        let lead = self.inserted(Lead(firstName: "Ada", lastName: "Lovelace", stage: .quoted))
        lead.followUpDate = self.date(2)

        let gear = self.inserted(GearItem(name: "600mm"))
        gear.isHired = true
        gear.hireReturnDate = self.date(5)
    }

    @Test("One call gathers every module's events for the range")
    func aggregatesAcrossModules() {
        self.seedAWeek()

        let events = self.aggregator.events(in: DateInterval(start: self.date(0), end: self.date(7)))

        #expect(events.count == 4)
        #expect(Set(events.map(\.id.facet)) == [.shoot, .due, .followUp, .hireReturn])
    }

    @Test("Results are ordered by when they start")
    func resultsAreSortedByStart() {
        self.seedAWeek()

        let events = self.aggregator.events(in: DateInterval(start: self.date(0), end: self.date(7)))

        #expect(events.map(\.startDate) == events.map(\.startDate).sorted())
    }

    @Test("Nothing outside the visible range is projected")
    func rangeIsHonoured() {
        self.seedAWeek()

        let events = self.aggregator.events(in: DateInterval(start: self.date(0), end: self.date(2, hour: 23)))

        #expect(events.map(\.id.facet) == [.followUp])
    }

    @Test("An empty store yields an empty calendar rather than failing")
    func emptyStoreIsEmpty() {
        #expect(self.aggregator.events(in: DateInterval(start: self.date(0), end: self.date(7))).isEmpty)
    }

    @Test("Sub-day detail arrives only when a day view asks for it")
    func scopeGatesSubEvents() {
        let sheet = self.inserted(CallSheet(title: "Wedding", shootDate: self.date(3)))
        let slot = self.inserted(
            CallSheetSlot(slotType: .shoot, title: "Ceremony",
                          startTime: self.date(3, hour: 13), endTime: self.date(3, hour: 14))
        )
        slot.callSheet = sheet

        let range = DateInterval(start: self.date(0), end: self.date(7))

        #expect(self.aggregator.events(in: range, scope: .overview).isEmpty)
        #expect(self.aggregator.events(in: range, scope: .day).map(\.id.facet) == [.slot])
    }

    @Test("A booking and its unsigned contract are two events from one fetch")
    func oneBookingCanYieldTwoEvents() {
        let booking = self.inserted(
            Booking(title: "Coastal Wedding", status: .confirmed,
                    startDate: self.date(6, hour: 9), endDate: self.date(6, hour: 18))
        )
        let contract = self.inserted(Contract(templateName: "Standard", status: .sent))
        contract.sentAt = self.date(-5)
        contract.booking = booking

        let events = self.aggregator.events(in: DateInterval(start: self.date(0), end: self.date(7)))

        #expect(Set(events.map(\.id.facet)) == [.shoot, .unsigned])
    }

    @Test("Every aggregated event can be routed back to a screen")
    func everyEventRoutesBack() {
        self.seedAWeek()

        let events = self.aggregator.events(in: DateInterval(start: self.date(0), end: self.date(7)))

        #expect(events.allSatisfy { $0.source.destination != nil })
    }
}

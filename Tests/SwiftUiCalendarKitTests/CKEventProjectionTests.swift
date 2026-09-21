// CKEventProjectionTests.swift

@testable import SwiftUiCalendarKit
import Foundation
import SwiftData
import Testing

@MainActor
@Suite("Calendar projections — one record, zero or more events")
struct CKEventProjectionTests {

    private let context: ModelContext
    private let calendar = Calendar.current

    init() throws {
        self.context = try ViewModelTestSupport.makeContext()
    }

    /// A visible month either side of today.
    ///
    /// Deliberately reaching into the past: an overdue invoice's due date is behind us by
    /// definition, so a range that started at today's midnight would exclude the very events the
    /// overdue facet exists for.
    private var range: DateInterval {
        DateInterval(start: self.date(-30), end: self.date(30))
    }

    private func date(_ dayOffset: Int, hour: Int = 12) -> Date {
        let day = self.calendar.date(byAdding: .day, value: dayOffset, to: Date().midnight) ?? Date()
        return self.calendar.date(bySettingHour: hour, minute: 0, second: 0, of: day) ?? day
    }

    private func invoice(due: Date, status: InvoiceStatus = .sent) -> Invoice {
        let invoice = Invoice(
            invoiceNumber: "INV-001", invoiceType: .full, amount: 500,
            taxRate: 20, issueDate: self.date(-10), dueDate: due
        )
        invoice.invoiceStatus = status
        self.context.insert(invoice)

        return invoice
    }

    private func booking(
        start: Date,
        end: Date,
        status: Booking.Status = .confirmed,
        allDay: Bool = false
    ) -> Booking {
        let booking = Booking(title: "Coastal Wedding", status: status, startDate: start, endDate: end)
        booking.isAllDay = allDay
        self.context.insert(booking)

        return booking
    }

    // MARK: - Invoice

    @Test("An unpaid invoice projects a deadline, not a zero-length block")
    func unpaidInvoiceIsADeadline() throws {
        let invoice = self.invoice(due: self.date(5))

        let event = try #require(
            InvoiceEvents.events(from: invoice, in: self.range, asOf: self.date(0)).first
        )

        #expect(event.kind.lane == .marker)
        #expect(event.id.facet == .due)
        #expect(event.startDate == invoice.dueDate)
    }

    @Test("Past its due date the same record projects the overdue facet")
    func overdueInvoiceUsesItsOwnFacet() throws {
        let invoice = self.invoice(due: self.date(-2))

        let event = try #require(
            InvoiceEvents.events(from: invoice, in: self.range, asOf: self.date(0)).first
        )

        #expect(event.id.facet == .overdue)
        #expect(event.id.recordID == invoice.id)
        #expect(event.title.contains("overdue"))
    }

    @Test("A paid or draft invoice is owed by nobody and projects nothing")
    func settledInvoicesProjectNothing() {
        for status in [InvoiceStatus.paid, .draft, .void, .refunded] {
            let invoice = self.invoice(due: self.date(3), status: status)

            #expect(
                InvoiceEvents.events(from: invoice, in: self.range, asOf: self.date(0)).isEmpty,
                "\(status) should not appear on the calendar"
            )
        }
    }

    @Test("An invoice due outside the visible range is not projected")
    func rangeIsFilteredInsideTheProjector() {
        let invoice = self.invoice(due: self.date(90))

        #expect(InvoiceEvents.events(from: invoice, in: self.range, asOf: self.date(0)).isEmpty)
    }

    @Test("A deleted invoice projects nothing rather than trapping")
    func deletedInvoiceProjectsNothing() {
        let invoice = self.invoice(due: self.date(5))
        self.context.delete(invoice)
        try? self.context.save()

        #expect(InvoiceEvents.events(from: invoice, in: self.range, asOf: self.date(0)).isEmpty)
    }

    // MARK: - Booking

    @Test("A same-day shoot is timed, and takes its icon from its status")
    func sameDayShootIsTimed() throws {
        let booking = self.booking(start: self.date(2, hour: 9), end: self.date(2, hour: 17))

        let event = try #require(BookingEvents.events(from: booking, in: self.range).first)

        #expect(event.kind == .timed(start: booking.shootStartDate, end: booking.shootEndDate))
        #expect(event.systemImage == Booking.Status.confirmed.systemImage)
        #expect(!event.isTentative)
    }

    @Test("An all-day shoot on one day is a band, not a 24-hour block")
    func allDayShootIsABand() throws {
        let booking = self.booking(
            start: self.date(2, hour: 9), end: self.date(2, hour: 17), allDay: true
        )

        let event = try #require(BookingEvents.events(from: booking, in: self.range).first)

        #expect(event.kind.lane == .band)
        #expect(event.isAllDay)
    }

    @Test("A shoot crossing midnight is a span whether or not it was entered as all-day")
    func multiDayShootIsASpan() throws {
        let booking = self.booking(start: self.date(2, hour: 18), end: self.date(4, hour: 11))

        let event = try #require(BookingEvents.events(from: booking, in: self.range).first)

        #expect(event.kind.lane == .band)
        #expect(event.isMultiDay())
    }

    @Test("A tentative shoot is marked so it can be drawn differently")
    func tentativeShootIsFlagged() throws {
        let booking = self.booking(
            start: self.date(2, hour: 9), end: self.date(2, hour: 17), status: .tentative
        )

        let event = try #require(BookingEvents.events(from: booking, in: self.range).first)

        #expect(event.isTentative)
    }

    @Test("A cancelled shoot occupies no time and projects nothing")
    func cancelledShootProjectsNothing() {
        let booking = self.booking(
            start: self.date(2, hour: 9), end: self.date(2, hour: 17), status: .cancelled
        )

        #expect(BookingEvents.events(from: booking, in: self.range).isEmpty)
    }

    @Test("A shoot that began before the range but runs into it is still projected")
    func spanningShootIntersectsTheRange() {
        let booking = self.booking(start: self.date(-3, hour: 9), end: self.date(1, hour: 17))
        let range = DateInterval(start: self.date(0), end: self.date(7))

        #expect(BookingEvents.events(from: booking, in: range).count == 1)
    }

    // MARK: - Routing back

    @Test("Every projected source routes to a destination")
    func sourcesRouteBack() throws {
        let booking = self.booking(start: self.date(2, hour: 9), end: self.date(2, hour: 17))
        let invoice = self.invoice(due: self.date(5))

        let bookingEvent = try #require(BookingEvents.events(from: booking, in: self.range).first)
        let invoiceEvent = try #require(
            InvoiceEvents.events(from: invoice, in: self.range, asOf: self.date(0)).first
        )

        #expect(bookingEvent.source.destination == .business(.bookingDetail(booking.id)))
        #expect(invoiceEvent.source.destination == .business(.invoiceDetail(invoice.id)))
    }
}

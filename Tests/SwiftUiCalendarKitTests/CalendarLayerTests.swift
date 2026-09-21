// CalendarLayerTests.swift

@testable import SwiftUiCalendarKit
import Foundation
import SwiftData
import Testing

@MainActor
@Suite("Calendar layers — what Settings switches off")
struct CalendarLayerTests {

    private let context: ModelContext
    private let calendar = Calendar.current

    init() throws {
        self.context = try ViewModelTestSupport.makeContext()
    }

    private func date(_ dayOffset: Int, hour: Int = 12) -> Date {
        let day = self.calendar.date(byAdding: .day, value: dayOffset, to: Date().midnight) ?? Date()
        return self.calendar.date(bySettingHour: hour, minute: 0, second: 0, of: day) ?? day
    }

    private var range: DateInterval {
        DateInterval(start: self.date(-30), end: self.date(30))
    }

    private func inserted<T: PersistentModel>(_ model: T) -> T {
        self.context.insert(model)
        return model
    }

    /// A booking, an invoice and a lead follow-up — three layers, one week.
    private func seed() {
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
    }

    private func events(hiding hidden: Set<CalendarLayer> = []) -> [CKEvent] {
        CKEventAggregator(context: self.context, hasProAccess: true, hiddenLayers: hidden)
            .events(in: self.range)
    }

    // MARK: - Defaults

    @Test("Everything is on to begin with")
    func defaultsToEverythingShown() {
        let settings = GeneralSettings()

        #expect(settings.hiddenCalendarLayers.isEmpty)
    }

    @Test("A layer nobody has hidden is shown, however many layers exist")
    func newLayersArriveSwitchedOn() {
        // The set stores what is *hidden*, so a case added later is on for everyone without a
        // migration. This is the whole reason for the inversion.
        let stored = [CalendarLayer.invoices.rawValue]
        let hidden = Set(stored.compactMap(CalendarLayer.init(rawValue:)))

        for layer in CalendarLayer.allCases where layer != .invoices {
            #expect(!hidden.contains(layer), "\(layer.displayName) should be on")
        }
    }

    @Test("A stored value with no case left is ignored rather than matched as a string")
    func unknownStoredLayersAreDropped() {
        let hidden = Set(["invoices", "somethingRemovedInALaterRelease"]
            .compactMap(CalendarLayer.init(rawValue:)))

        #expect(hidden == [.invoices])
    }

    // MARK: - Filtering

    @Test("Hiding a layer removes exactly that layer")
    func hidingOneLayerRemovesOnlyIt() {
        self.seed()

        let all = Set(self.events().map(\.layer))
        #expect(all == [.bookings, .invoices, .leads])

        let withoutInvoices = Set(self.events(hiding: [.invoices]).map(\.layer))
        #expect(withoutInvoices == [.bookings, .leads])
    }

    @Test("Hiding everything leaves an empty calendar rather than failing")
    func hidingEverythingIsAllowed() {
        self.seed()

        #expect(self.events(hiding: Set(CalendarLayer.allCases)).isEmpty)
    }

    // MARK: - The mapping

    @Test("Every source belongs to a layer, so nothing is un-hideable")
    func everySourceMapsToALayer() {
        let sources: [CKEventSource] = [
            .booking(UUID()), .invoice(UUID()), .lead(UUID()), .gearItem(UUID()),
            .permit(UUID()), .trip(UUID()), .studioBooking(UUID()), .callSheet(UUID()),
            .crew(UUID()), .shotList(UUID()), .optimalWindow(UUID())
        ]

        // Compiles only because `layer` is exhaustive; asserts the mapping is total in practice.
        #expect(Set(sources.map(\.layer)).count == 10)
    }

    @Test("Call sheets and crew share one switch, because they are one Pro feature")
    func crewAndCallSheetsShareALayer() {
        #expect(CKEventSource.callSheet(UUID()).layer == .crew)
        #expect(CKEventSource.crew(UUID()).layer == .crew)
    }

    @Test("The unsigned-contract alert is on the contracts switch, not on shoots")
    func contractAlertHasItsOwnLayer() throws {
        let booking = self.inserted(
            Booking(title: "Coastal Wedding", status: .confirmed,
                    startDate: self.date(10, hour: 9), endDate: self.date(10, hour: 18))
        )
        let contract = self.inserted(Contract(templateName: "Standard", status: .sent))
        contract.sentAt = self.date(-5)
        contract.booking = booking

        // It is projected from a `Booking` and so carries a booking source — the facet is what
        // tells them apart, the same distinction that lets one invoice be both due and overdue.
        let alert = try #require(self.events().first { $0.id.facet == .unsigned })
        #expect(alert.layer == .contracts)

        let shoot = try #require(self.events().first { $0.id.facet == .shoot })
        #expect(shoot.layer == .bookings)

        // Turning shoots off must not take the contract reminder with it.
        let layers = Set(self.events(hiding: [.bookings]).map(\.layer))
        #expect(layers == [.contracts])
    }

    @Test("Sun and moon is a layer with no events behind it")
    func sunAndMoonIsNotAnEventLayer() {
        self.seed()

        // Nothing the aggregator produces carries it, which is why the view has to stop the
        // ephemeris solve itself rather than relying on the filter.
        #expect(!self.events().contains { $0.layer == .sunAndMoon })
        #expect(CalendarLayer.allCases.contains(.sunAndMoon))
    }

    @Test("Every layer has something to show for itself in Settings")
    func everyLayerIsPresentable() {
        for layer in CalendarLayer.allCases {
            #expect(!layer.displayName.isEmpty)
            #expect(!layer.systemImage.isEmpty)
            #expect(!layer.footnote.isEmpty, "\(layer.displayName) needs a line saying what it hides")
        }
    }
}

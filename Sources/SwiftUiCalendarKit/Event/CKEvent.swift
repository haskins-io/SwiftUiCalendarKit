//
//  CKEvent.swift
//  
//
//  Created by Mark Haskins on 12/04/2024.
//

import SwiftUI

/// What the calendar consumes. Never a `@Model`.
nonisolated struct CKEvent: Identifiable, Hashable, Sendable {

    /// What sort of thing this is, which decides how it is drawn.
    ///
    /// Carrying the dates in here rather than as flat `startDate`/`endDate` is the fix for §3.4:
    /// a deadline has no duration, so under the old shape it came out `startDate == endDate`,
    /// which `CKEventViewData` turned into a height of zero and `CKUtils` then filtered away
    /// before layout. Every Tier 2 item in §2.2 — every invoice due date, every service due,
    /// every follow-up — was zero-length, so none of them could appear at all. A kind cannot be
    /// asked for a duration it does not have.
    enum Kind: Hashable, Sendable {

        /// Occupies real time and can collide — draw on the hour grid.
        case timed(start: Date, end: Date)

        /// Occupies a whole day.
        case allDay(Date)

        /// A point with consequences and no duration — draw as a marker.
        case deadline(Date)

        /// Spans several days — draw as a band above the grid.
        case span(from: Date, through: Date)
    }

    let id: CKEventID
    let kind: Kind
    let title: String
    let subtitle: String?

    /// Derived at projection time, never stored on a model.
    ///
    /// A stored `systemImage` was added to `Booking` to satisfy the old protocol and has since
    /// been taken back out (§3.1, §5.1): it duplicated `Booking.Status.systemImage`, nothing
    /// ever assigned it, and it was a per-record string replicated to every device and to
    /// CloudKit — permanently, since a field deployed to production can never be removed.
    let systemImage: String

    let tint: Color

    /// Where tapping the event goes back to.
    let source: CKEventSource

    /// e.g. an unconfirmed booking — draw hatched.
    let isTentative: Bool

    init(
        id: CKEventID,
        kind: Kind,
        title: String,
        subtitle: String? = nil,
        systemImage: String = "",
        tint: Color,
        source: CKEventSource,
        isTentative: Bool = false
    ) {
        self.id = id
        self.kind = kind
        self.title = title
        self.subtitle = subtitle
        self.systemImage = systemImage
        self.tint = tint
        self.source = source
        self.isTentative = isTentative
    }
}

/// Identity that survives projection and routes back to the record.
///
/// The `facet` is what solves §3.2: one `Invoice` yields `CKEventID(recordID: inv.id,
/// facet: .due)` and `…facet: .overdue` as two distinct events with the same origin. It is also
/// what lets the layout dictionaries key on a real type instead of `AnyHashable`, which the old
/// `any CKEventSchema` input forced on them.
nonisolated struct CKEventID: Hashable, Sendable {

    /// Which of a record's several dates this event came from.
    ///
    /// A closed set rather than the free string §4.1 sketched: a typo in one projector would
    /// otherwise mint a second identity for the same event and defeat the de-duplication this
    /// exists to provide. Each new projector adds the cases it emits.
    ///
    /// Several records appear here more than once, which is the whole argument of §3.2: a
    /// `Permit` is a validity band *and* a decision date *and* an expiry, and a type can satisfy
    /// a protocol only once.
    enum Facet: String, Hashable, Sendable {

        /// The committed time itself — a shoot, a hire, a stay, a journey.
        case shoot
        case hire
        case stay
        case travel
        case trip
        case call
        case slot
        case target

        /// Money.
        case due
        case overdue

        /// Dates with consequences.
        case followUp
        case serviceDue
        case hireReturn
        case cancellation

        /// A permit's dates. There is no `validity` case: a year-long band filled every cell of
        /// every month and left no room for anything that actually happens — see `PermitEvents`.
        case decision
        case expiry

        /// Derived rather than stored: a booking approaching with an unsigned contract.
        case unsigned

        /// A ranked shooting window (§2.3).
        case optimal

        // §7 — the celestial tier. Each names what the event *is*, because the source cannot:
        // they all arrive as `.celestial`.
        case solarEclipse
        case lunarEclipse
        case meteorPeak
        case solstice
        case equinox
        case supermoon
        case micromoon
        case milkyWaySeason
    }

    /// The model's own `id`.
    let recordID: UUID

    let facet: Facet
}


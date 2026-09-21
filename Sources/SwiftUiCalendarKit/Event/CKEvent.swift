//
//  CKEvent.swift
//  
//
//  Created by Mark Haskins on 12/04/2024.
//

import SwiftUI

/// What the calendar consumes. Never a `@Model`.
nonisolated struct CKEvent: Identifiable, Hashable, Sendable {

    public typealias Id = UUID
    public var id: Id = UUID()

    /// What sort of thing this is, which decides how it is drawn.
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

    let kind: Kind
    let title: String
    let subtitle: String?
    let systemImage: String

    let tint: Color

    /// Where tapping the event goes back to.
    let source: CKEventSource

    let isTentative: Bool

    init(
        kind: Kind,
        title: String,
        subtitle: String? = nil,
        systemImage: String = "",
        tint: Color,
        source: CKEventSource,
        isTentative: Bool = false
    ) {
        self.kind = kind
        self.title = title
        self.subtitle = subtitle
        self.systemImage = systemImage
        self.tint = tint
        self.source = source
        self.isTentative = isTentative
    }
}

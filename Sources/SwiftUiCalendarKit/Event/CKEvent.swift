//
//  CKEvent.swift
//  
//
//  Created by Mark Haskins on 12/04/2024.
//

import SwiftUI

/// What the calendar consumes. Never a `@Model`.
public nonisolated struct CKEvent: Identifiable, Hashable, Sendable {

    /// What sort of thing this is, which decides how it is drawn.
    public enum Kind: Hashable, Sendable {

        /// Occupies real time and can collide — draw on the hour grid.
        case timed(start: Date, end: Date)

        /// Occupies a whole day.
        case allDay(Date)

        /// A point with consequences and no duration — draw as a marker.
        case deadline(Date)

        /// Spans several days — draw as a band above the grid.
        case span(from: Date, through: Date)
    }

    public let id = CKEventID()
    public let kind: Kind
    public let title: String
    public let subtitle: String?

    /// Derived at projection time, never stored on a model.
    public let systemImage: String

    public let tint: Color

    /// e.g. an unconfirmed event — draw hatched.
    public let isTentative: Bool

    public init(
        kind: Kind,
        title: String,
        subtitle: String? = nil,
        systemImage: String = "",
        tint: Color,
        isTentative: Bool = false
    ) {
        self.kind = kind
        self.title = title
        self.subtitle = subtitle
        self.systemImage = systemImage
        self.tint = tint
        self.isTentative = isTentative
    }
}

public nonisolated struct CKEventID: Hashable, Sendable {
    let recordID = UUID()
}

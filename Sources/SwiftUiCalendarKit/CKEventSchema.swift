//
//  CKEventSchema.swift
//
//  Created by Mark Haskins on 11/04/2024.
//

import SwiftUI

///
/// CKEventSchema
///
/// This protocol show be implemented by any class that you would want to represent on a calendar.
///
/// - Parameter startDate: The start of time of an event
/// - Parameter endDate: The end time of an event
/// - Parameter isAllDay: Is the event take up the whole day
/// - Parameter text: The text to show on the calendar
/// - Parameter primaryText: a primary line of text that can be shown on a calendar event
/// - Parameter secondaryText: a secondary line of text that can be shown on a calendar event
/// - Parameter backgroundColor: The colour used to identify the event type
/// - Parameter showTotalTime: When set will show the amount of time the event runs for
/// - Parameter sfImage: SF Image to show alongside the event primary description
/// - Parameter image:Image to show alongside the event primary description

public protocol CKEventSchema: Identifiable {

    var anyHashableID: AnyHashable { get }

    var startDate: Date { get set }
    var endDate: Date { get set }
    var isAllDay: Bool { get set }

    @available(*, deprecated, message: "This now deprecated, use Primary text instead")
    var text: String { get set }
    var primaryText: String { get set }
    var secondaryText: String { get set }

    var backgroundColor: String { get set }

    var sfImage: String { get set }
    var image: String { get set }

    var showTotalTime: Bool { get set }

    /// Returns the colur of the event
    func backgroundAsColor() -> Color

    /// Returns the total time of the even
    func totalTime() -> String}

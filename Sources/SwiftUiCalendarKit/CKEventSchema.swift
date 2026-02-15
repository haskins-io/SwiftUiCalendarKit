//
//  Event.swift
//  SwiftUiCalendars
//
//  Created by Mark Haskins on 11/04/2024.
//

import SwiftUI

///
/// CKEventSchema
///
/// This protocol show be implemented by any class that you would want to represent on a calendar.
///
/// - Paramters
///   - startDate: The start of time of an event
///   - endDate: The end time of an event
///   - text: The text to show on the calendar
///   - primaryText: a primary line of text that can be shown on a calendar event
///   - secondaryText: a secondary line of text that can be shown on a calendar event
///   - backgroundColor: The colour used to identify the event type
///   - showTotalTime: When set will show the amount of time the event runs for
///
public protocol CKEventSchema: Identifiable {

    var anyHashableID: AnyHashable { get }

    var startDate: Date  {get set}
    var endDate: Date  {get set}

    var text: String  {get set}
    var primaryText: String  {get set}
    var secondaryText: String  {get set}

    var backgroundColor: String  {get set}

    var showTotalTime: Bool {get  set}

    /// Returns the colur of the event
    func backgroundAsColor() -> Color

    /// Returns the total time of the even
    func totalTime() -> String}

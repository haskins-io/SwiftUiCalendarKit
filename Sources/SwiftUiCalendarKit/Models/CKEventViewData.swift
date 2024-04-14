//
//  File.swift
//  
//
//  Created by Mark Haskins on 14/04/2024.
//

import SwiftUI

class EventViewData: Hashable {

    static func == (lhs: EventViewData, rhs: EventViewData) -> Bool {
        return lhs.id == rhs.id && lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(id)
    }

    let id = UUID()

    let calendar = Calendar(identifier: .gregorian)

    let event: any CKEventSchema
    let overlapsWith: CGFloat
    let position: CGFloat

    let duration: CGFloat
    let height: CGFloat

    let day: Int
    let hour: Int
    let minute: Int

    let cellWidth: CGFloat
    let eventWidth: CGFloat

    let yOffset: CGFloat

    init(event: any CKEventSchema, overlapsWith: CGFloat, position: CGFloat, width: CGFloat) {

        self.event = event
        self.overlapsWith = overlapsWith
        self.position = position
        self.cellWidth = width

        self.duration = event.endDate.timeIntervalSince(event.startDate)
        height = duration / 60 / 60 * CKTimeline.hourHeight

        day = calendar.component(.day, from: event.startDate)
        hour = calendar.component(.hour, from: event.startDate)
        minute = calendar.component(.minute, from: event.startDate)

        if position > 1 {
            eventWidth = ((width - 20) / overlapsWith)
        } else {
            eventWidth = (width / overlapsWith)
        }

        yOffset = (Double(hour) * (CKTimeline.hourHeight)) + Double(minute)
    }
}

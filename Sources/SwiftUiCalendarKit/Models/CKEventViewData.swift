//
//  File.swift
//  
//
//  Created by Mark Haskins on 14/04/2024.
//

import SwiftUI

class CKEventViewData: Identifiable {

    public typealias Id = UUID
    let id = UUID()

    public var anyHashableID: AnyHashable { AnyHashable(id) }

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

    public init(
        event: any CKEventSchema,
        overlapsWith: CGFloat,
        position: CGFloat,
        width: CGFloat,
        startHour: Int = 0
    ) {

        self.event = event
        self.overlapsWith = overlapsWith
        self.position = position
        self.cellWidth = width

        self.duration = event.endDate.timeIntervalSince(event.startDate)
        height = duration / 60 / 60 * CKTimeline.hourHeight

        day = calendar.component(.day, from: event.startDate)
        hour = calendar.component(.hour, from: event.startDate) - startHour
        minute = calendar.component(.minute, from: event.startDate)

        eventWidth = (width / overlapsWith) - 5

        yOffset = (Double(hour) * (CKTimeline.hourHeight)) + Double(minute)
    }
}


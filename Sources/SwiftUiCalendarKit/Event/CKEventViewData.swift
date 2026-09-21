//
//  CKEventViewData.swift
//  
//
//  Created by Mark Haskins on 14/04/2024.
//

import SwiftUI

/// One event's geometry on the hour grid.
nonisolated struct CKEventViewData: Identifiable, Sendable {

    public typealias Id = UUID
    public var id: Id = UUID()

    let event: CKEvent

    let start: Date
    let end: Date

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

    init?(
        event: CKEvent,
        overlapsWith: CGFloat,
        position: CGFloat,
        width: CGFloat,
        calendar: Calendar = .current
    ) {
        guard case .timed(let start, let end) = event.kind, end > start else {
            return nil
        }

        self.event = event
        self.start = start
        self.end = end

        self.overlapsWith = overlapsWith
        self.position = position
        self.cellWidth = width

        self.duration = end.timeIntervalSince(start)
        self.height = self.duration / 60 / 60 * CKTimeline.hourHeight

        self.day = calendar.component(.day, from: start)
        self.hour = calendar.component(.hour, from: start)
        self.minute = calendar.component(.minute, from: start)

        self.eventWidth = (width / overlapsWith) - 5

        self.yOffset = (Double(self.hour) * CKTimeline.hourHeight) + Double(self.minute)
    }
}

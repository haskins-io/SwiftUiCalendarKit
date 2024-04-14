//
//  File.swift
//  
//
//  Created by Mark Haskins on 13/04/2024.
//

import Foundation

class CKUtils {

    static func generateEventViewData(date: Date, events: [any CKEventSchema], width: CGFloat) -> [EventViewData] {

        let calendar = Calendar(identifier: .gregorian)

        var pos1: [EventViewData] = []
        var pos2: [EventViewData] = []
        var pos3: [EventViewData] = []
        var pos4: [EventViewData] = []
        var pos5: [EventViewData] = []

        for event in events {

            if !calendar.isDate(event.startDate, inSameDayAs: date) {
                continue
            }

            if !overLappings(event, pos1) {
                pos1.append(EventViewData(event: event, overlapsWith: overLappingCount(event, events), position: 1, width: width))
            } else if !overLappings(event, pos2) {
                pos2.append(EventViewData(event: event, overlapsWith: overLappingCount(event, events), position: 2, width: width))
            } else if !overLappings(event, pos3) {
                pos3.append(EventViewData(event: event, overlapsWith: overLappingCount(event, events), position: 3, width: width))
            } else if !overLappings(event, pos4) {
                pos4.append(EventViewData(event: event, overlapsWith: overLappingCount(event, events), position: 4, width: width))
            } else if !overLappings(event, pos5) {
                pos5.append(EventViewData(event: event, overlapsWith: overLappingCount(event, events), position: 5, width: width))
            }
        }

        var eventData: [EventViewData] = []
        eventData.append(contentsOf: pos1)
        eventData.append(contentsOf: pos2)
        eventData.append(contentsOf: pos3)
        eventData.append(contentsOf: pos4)
        eventData.append(contentsOf: pos5)

        return eventData
    }

    static func overLappings(_ currentEvent: any CKEventSchema, _ events: [EventViewData]) -> Bool {

        for event in events {
            if doEventsOverlap(currentEvent, event.event) {
                return true
            }
        }

        return false
    }

    static func overLappingCount(_ currentEvent: any CKEventSchema, _ events: [any CKEventSchema]) -> CGFloat {

        var count: CGFloat = 1

        for event in events {
            if currentEvent.anyHashableID != event.anyHashableID && doEventsOverlap(currentEvent, event) {
                count += 1
            }
        }

        return count
    }

    static func doEventsOverlap(_ event1: any CKEventSchema, _ event2: any CKEventSchema) -> Bool {
        let leftRange = event1.startDate ... event1.endDate
        let rightRange = event2.startDate ... event2.endDate

        return leftRange.overlaps(rightRange)
    }
}

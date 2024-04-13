//
//  File.swift
//  
//
//  Created by Mark Haskins on 13/04/2024.
//

import Foundation

class CKUtils {

    static func overLappingEventsCount(_ currentEvent: any CKEventSchema, _ events: [any CKEventSchema]) -> CGFloat {

        var count: CGFloat = 0

        for event in events {
            if doEventsOverlap(currentEvent, event) {
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

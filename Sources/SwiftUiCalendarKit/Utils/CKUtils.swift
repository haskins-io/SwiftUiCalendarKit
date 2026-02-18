//
//  CKUtils.swift
//  
//
//  Created by Mark Haskins on 13/04/2024.
//

import Foundation

enum CKUtils {

    static func currentTimelinePosition(calendar: Calendar = .current) -> Double {
        let now = Date()
        let hour = calendar.component(.hour, from: now)
        let minute = calendar.component(.minute, from: now)
        return (Double(hour) * CKTimeline.hourHeight) + Double(minute) + 30.0
    }

    static func doesEventOccurOnDate(event: any CKEventSchema, date: Date) -> Bool {

        let start = event.startDate.midnight
        let dayAfter = calendar.date(byAdding: .day, value: 1, to: event.endDate)?.midnight ?? event.endDate.midnight
        let end = calendar.date(byAdding: .minute, value: -1, to: dayAfter) ?? dayAfter

        let eventRange = start...end
        if eventRange.contains(date) {
            return true
        }

        return false
    }

    static func generateEventViewData(
        date: Date,
        events: [any CKEventSchema],
        width: CGFloat
    ) -> [CKEventViewData] {

        let weekRange = date.fetchWeekRange()

        // Pre-compute overlap counts once per event, keyed by ID.
        var overlapCounts: [AnyHashable: CGFloat] = [:]
        for event in events where weekRange.contains(event.startDate) {
            overlapCounts[event.anyHashableID] = overLappingCount(event, events)
        }

        // Assign each event to the first position bucket it doesn't overlap with.
        var positions: [[CKEventViewData]] = []

        for event in events {
            guard weekRange.contains(event.startDate) else {
                continue
            }

            guard event.endDate > event.startDate else {
                continue
            }

            let overlapCount = overlapCounts[event.anyHashableID] ?? 1

            if let bucketIndex = positions.firstIndex(where: { !overLappings(event, $0) }) {
                positions[bucketIndex].append(
                    CKEventViewData(
                        event: event,
                        overlapsWith: overlapCount,
                        position: CGFloat(bucketIndex + 1),
                        width: width
                    )
                )
            } else {
                // No suitable bucket found — start a new one.
                positions.append([
                    CKEventViewData(
                        event: event,
                        overlapsWith: overlapCount,
                        position: CGFloat(positions.count + 1),
                        width: width
                    )
                ])
            }
        }

        return positions.flatMap { $0 }
    }

    static func overLappings(_ currentEvent: any CKEventSchema, _ events: [CKEventViewData]) -> Bool {

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

        if event1.isAllDay || event2.isAllDay {
            return false
        }

        guard event2.endDate > event1.startDate, event1.endDate > event2.startDate else {
            return false
        }

        let event1Add1Sec = Calendar.current.date(byAdding: .second, value: 1, to: event1.startDate) ?? event1.startDate
        let event2Add1Sec = Calendar.current.date(byAdding: .second, value: 1, to: event2.startDate) ?? event2.startDate

        let leftRange = event1Add1Sec ... event1.endDate
        let rightRange = event2Add1Sec ... event2.endDate

        return leftRange.overlaps(rightRange)
    }
}

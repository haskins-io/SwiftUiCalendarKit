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

        let calendar = Calendar.current

        let start = event.startDate.midnight
        let dayAfter = calendar.date(byAdding: .day, value: 1, to: event.endDate)?.midnight ?? event.endDate.midnight
        let end = calendar.date(byAdding: .minute, value: -1, to: dayAfter) ?? dayAfter

        let eventRange = start...end
        if eventRange.contains(date) {
            return true
        }

        return false
    }

    private static func buildOverlapGroups(
        _ filteredEvents: [any CKEventSchema],
        _ processedEvents: inout Set<AnyHashable>,
        _ eventGroups: inout [[any CKEventSchema]]
    ) {
        for event in filteredEvents {
            if processedEvents.contains(event.anyHashableID) {
                continue
            }

            // Start a new group with this event
            var group: [any CKEventSchema] = [event]
            var toProcess: [any CKEventSchema] = [event]
            processedEvents.insert(event.anyHashableID)

            // Find all events that overlap with any event in the group
            while !toProcess.isEmpty {
                let currentEvent = toProcess.removeFirst()

                for otherEvent in filteredEvents {
                    if processedEvents.contains(otherEvent.anyHashableID) {
                        continue
                    }

                    // Check if this event overlaps with the current event
                    if doEventsConflictForPlacement(currentEvent, otherEvent) {
                        group.append(otherEvent)
                        toProcess.append(otherEvent)
                        processedEvents.insert(otherEvent.anyHashableID)
                    }
                }
            }

            eventGroups.append(group)
        }
    }

    private static func assignColumns(
        _ eventGroups: [[any CKEventSchema]],
        _ eventColumns: inout [AnyHashable: Int],
        _ groupMaxColumns: inout [AnyHashable: Int]
    ) {

        for group in eventGroups {
            // Sort events in this group by start time, then by end time
            let sortedGroup = group.sorted {
                $0.startDate < $1.startDate || ($0.startDate == $1.startDate && $0.endDate < $1.endDate)
            }

            // Track column end times for this group only
            var columnEndTimes: [Date] = []

            // Assign each event in the group to the leftmost available column
            for event in sortedGroup {
                // Find the first column that's free (ends at or before this event's start)
                if let columnIndex = columnEndTimes.firstIndex(where: { $0 <= event.startDate }) {
                    // Reuse this column
                    eventColumns[event.anyHashableID] = columnIndex
                    columnEndTimes[columnIndex] = event.endDate
                } else {
                    // Need a new column
                    let newColumnIndex = columnEndTimes.count
                    eventColumns[event.anyHashableID] = newColumnIndex
                    columnEndTimes.append(event.endDate)
                }
            }

            // The max column count for this group
            let maxColumnsForGroup = columnEndTimes.count
            for event in group {
                groupMaxColumns[event.anyHashableID] = maxColumnsForGroup
            }
        }
    }

    private static func createViewData(
        _ filteredEvents: [any CKEventSchema],
        _ eventColumns: inout [AnyHashable: Int],
        _ groupMaxColumns: inout [AnyHashable: Int],
        _ eventViewDataArray: inout [CKEventViewData],
        _ width: CGFloat
    ) {
        for event in filteredEvents {
            guard let column = eventColumns[event.anyHashableID],
                  let maxColumns = groupMaxColumns[event.anyHashableID] else { continue }

            eventViewDataArray.append(
                CKEventViewData(
                    event: event,
                    overlapsWith: CGFloat(maxColumns),
                    position: CGFloat(column + 1),
                    width: width
                )
            )
        }
    }

    static func generateEventViewData(
        date: Date,
        events: [any CKEventSchema],
        width: CGFloat
    ) -> [CKEventViewData] {

        let weekRange = date.fetchWeekRange()

        // Filter and sort events by start time, then by end time
        let filteredEvents = events.filter { event in
            weekRange.contains(event.startDate) && event.endDate > event.startDate
        }.sorted { $0.startDate < $1.startDate || ($0.startDate == $1.startDate && $0.endDate < $1.endDate) }

        // Step 1: Build overlap groups - events that overlap with each other form a group
        var eventGroups: [[any CKEventSchema]] = []
        var processedEvents: Set<AnyHashable> = []

        buildOverlapGroups(filteredEvents, &processedEvents, &eventGroups)

        // Step 2: For each group, assign columns independently
        var eventColumns: [AnyHashable: Int] = [:]
        var groupMaxColumns: [AnyHashable: Int] = [:]

        assignColumns(eventGroups, &eventColumns, &groupMaxColumns)

        // Step 3: Create view data for each event
        var eventViewDataArray: [CKEventViewData] = []

        createViewData(filteredEvents, &eventColumns, &groupMaxColumns, &eventViewDataArray, width)

        return eventViewDataArray
    }

    // Events that touch at boundaries CAN share a bucket, but overlapping events cannot
    static private func doEventsConflictForPlacement(_ event1: any CKEventSchema, _ event2: any CKEventSchema) -> Bool {

        if event1.isAllDay || event2.isAllDay {
            return false
        }

        // Two events conflict for placement only if their time ranges truly overlap
        // Events that merely touch at a boundary (one ends when another starts) can share a bucket
        // Using max/min to ensure the check is symmetric
        let maxStart = max(event1.startDate, event2.startDate)
        let minEnd = min(event1.endDate, event2.endDate)

        // If maxStart < minEnd, they have true overlap - conflict!
        // If maxStart == minEnd, they only touch at a point - NO conflict
        return maxStart < minEnd
    }
}

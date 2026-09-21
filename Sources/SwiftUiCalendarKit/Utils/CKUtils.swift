//
//  CKUtils.swift
//  
//
//  Created by Mark Haskins on 13/04/2024.
//

import Foundation

nonisolated enum CKUtils {

    static func currentTimelinePosition(calendar: Calendar = .current) -> Double {
        let now = Date()
        let hour = calendar.component(.hour, from: now)
        let minute = calendar.component(.minute, from: now)
        return (Double(hour) * CKTimeline.hourHeight) + Double(minute) + 30.0
    }

    static func doesEventOccurOnDate(event: CKEvent, date: Date) -> Bool {

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
        _ filteredEvents: [CKEvent],
        _ processedEvents: inout Set<CKEventID>,
        _ eventGroups: inout [[CKEvent]]
    ) {
        for event in filteredEvents {
            if processedEvents.contains(event.id) {
                continue
            }

            // Start a new group with this event
            var group: [CKEvent] = [event]
            var toProcess: [CKEvent] = [event]
            processedEvents.insert(event.id)

            // Find all events that overlap with any event in the group
            while !toProcess.isEmpty {
                let currentEvent = toProcess.removeFirst()

                for otherEvent in filteredEvents {
                    if processedEvents.contains(otherEvent.id) {
                        continue
                    }

                    // Check if this event overlaps with the current event
                    if doEventsConflictForPlacement(currentEvent, otherEvent) {
                        group.append(otherEvent)
                        toProcess.append(otherEvent)
                        processedEvents.insert(otherEvent.id)
                    }
                }
            }

            eventGroups.append(group)
        }
    }

    private static func assignColumns(
        _ eventGroups: [[CKEvent]],
        _ eventColumns: inout [CKEventID: Int],
        _ groupMaxColumns: inout [CKEventID: Int]
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
                    eventColumns[event.id] = columnIndex
                    columnEndTimes[columnIndex] = event.endDate
                } else {
                    // Need a new column
                    let newColumnIndex = columnEndTimes.count
                    eventColumns[event.id] = newColumnIndex
                    columnEndTimes.append(event.endDate)
                }
            }

            // The max column count for this group
            let maxColumnsForGroup = columnEndTimes.count
            for event in group {
                groupMaxColumns[event.id] = maxColumnsForGroup
            }
        }
    }

    private static func createViewData(
        _ filteredEvents: [CKEvent],
        _ eventColumns: inout [CKEventID: Int],
        _ groupMaxColumns: inout [CKEventID: Int],
        _ eventViewDataArray: inout [CKEventViewData],
        _ width: CGFloat
    ) {
        for event in filteredEvents {
            guard let column = eventColumns[event.id],
                  let maxColumns = groupMaxColumns[event.id] else { continue }

            guard let viewData = CKEventViewData(
                event: event,
                overlapsWith: CGFloat(maxColumns),
                position: CGFloat(column + 1),
                width: width
            ) else { continue }

            eventViewDataArray.append(viewData)
        }
    }

    /// Lays out the events that belong on the hour grid for the week containing `date`.
    ///
    /// Only `.timed` events reach here. The other three kinds are not dropped, as they
    /// effectively were before — they belong to the band and marker lanes and are selected with
    /// ``bandEvents(in:events:)`` and ``markerEvents(in:events:)``.
    static func generateEventViewData(
        date: Date,
        events: [CKEvent],
        width: CGFloat
    ) -> [CKEventViewData] {

        let weekRange = date.fetchWeekRange()

        // Filter to the grid lane and sort by start time, then by end time
        let filteredEvents = events
            .filter { $0.kind.lane == .grid && weekRange.contains($0.startDate) }
            .sorted { $0.startDate < $1.startDate || ($0.startDate == $1.startDate && $0.endDate < $1.endDate) }

        // Step 1: Build overlap groups - events that overlap with each other form a group
        var eventGroups: [[CKEvent]] = []
        var processedEvents: Set<CKEventID> = []

        buildOverlapGroups(filteredEvents, &processedEvents, &eventGroups)

        // Step 2: For each group, assign columns independently
        var eventColumns: [CKEventID: Int] = [:]
        var groupMaxColumns: [CKEventID: Int] = [:]

        assignColumns(eventGroups, &eventColumns, &groupMaxColumns)

        // Step 3: Create view data for each event
        var eventViewDataArray: [CKEventViewData] = []

        createViewData(filteredEvents, &eventColumns, &groupMaxColumns, &eventViewDataArray, width)

        return eventViewDataArray
    }

    /// The all-day and multi-day events overlapping `interval`, for the band above the grid.
    ///
    /// Intersection rather than the grid lane's start-date containment: a trip that began
    /// before the visible week still belongs on it.
    static func bandEvents(in interval: DateInterval, events: [CKEvent]) -> [CKEvent] {
        events
            .filter { $0.kind.lane == .band && $0.intersects(interval) }
            .sorted { $0.startDate < $1.startDate || ($0.startDate == $1.startDate && $0.endDate > $1.endDate) }
    }

    /// The deadlines falling inside `interval`, for the day-header markers.
    static func markerEvents(in interval: DateInterval, events: [CKEvent]) -> [CKEvent] {
        events
            .filter { $0.kind.lane == .marker && interval.contains($0.startDate) }
            .sorted { $0.startDate < $1.startDate }
    }

    // Events that touch at boundaries CAN share a bucket, but overlapping events cannot
    static private func doEventsConflictForPlacement(_ event1: CKEvent, _ event2: CKEvent) -> Bool {

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

//
//  SwiftUIView.swift
//  SwiftUiCalendarKit
//
//  Created by Mark Haskins on 18/02/2026.
//

import SwiftUI

/// `CKCompactAgenda` can be used for showing an ordered list of events
///
///     CKCompactAgenda(
///         detail: { event in EventDetail(event: event) },
///         events: events
///     )
///
/// - Parameter detail: The view that should be shown when an event in the Calendar is tapped.
/// - Parameter events: an array of events that conform to ``CKEventSchema``.

public struct CKCompactAgenda<Detail: View>: View {

    @Environment(\.ckConfig)
    private var config

    private let detail: (any CKEventSchema) -> Detail
    private let events: [any CKEventSchema]

    private let calendar = Calendar.current

    public init(
        @ViewBuilder detail: @escaping (any CKEventSchema) -> Detail,
        events: [any CKEventSchema]
    ) {
        self.detail = detail
        self.events = events
    }

    public var body: some View {
        List {
            ForEach(groupedEvents) { dayEvents in
                Section {
                    ForEach(dayEvents.events, id: \.anyHashableID) { event in
                        NavigationLink {
                            detail(event)
                        } label: {
                            agendaEventRow(event: event)
                        }
                        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                    }
                } header: {
                    agendaSectionHeader(date: dayEvents.date)
                }
            }
        }
        .listStyle(.plain)
    }

    @ViewBuilder
    private func agendaSectionHeader(date: Date) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(date.formatted(.dateTime.weekday(.wide)))
                Text(date.formatted(.dateTime.day().month(.abbreviated)))
            }
            .font(.subheadline)
            .foregroundStyle(.blue)
            .textCase(nil)
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private func agendaEventRow(event: any CKEventSchema) -> some View {
        HStack(alignment: .top, spacing: 12) {
            // Time column
            VStack(alignment: .trailing, spacing: 0) {
                if event.isAllDay {
                    Text("All-Day")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text(event.startDate.formatted(.dateTime.hour().minute()))
                        .font(.caption)
                    Text(event.endDate.formatted(.dateTime.hour().minute()))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 50, alignment: .trailing)

            // Event details
            VStack(alignment: .leading, spacing: 2) {
                Text(event.text)
                    .font(.body)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(event.backgroundAsColor()).opacity(0.3))
            .overlay {
                HStack {
                    Rectangle()
                        .fill(event.backgroundAsColor())
                        .frame(maxHeight: .infinity, alignment: .leading)
                        .frame(width: 4)
                    Spacer()
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
    }
}

// MARK: - Data Grouping
extension CKCompactAgenda {

    private struct DayEvents: Identifiable {
        let id = UUID()
        let date: Date
        let events: [any CKEventSchema]
    }

    private var groupedEvents: [DayEvents] {
        var eventsByDay: [Date: [any CKEventSchema]] = [:]

        // Process each event and add it to all days it spans
        for event in events {
            let startDay = calendar.startOfDay(for: event.startDate)
            let endDay = calendar.startOfDay(for: event.endDate)

            // For multi-day events, add to each day in the range
            var currentDay = startDay
            while currentDay <= endDay {
                if eventsByDay[currentDay] == nil {
                    eventsByDay[currentDay] = []
                }
                eventsByDay[currentDay]?.append(event)

                // Move to next day
                guard let nextDay = calendar.date(byAdding: .day, value: 1, to: currentDay) else {
                    break
                }
                currentDay = nextDay
            }
        }

        // Convert to array and sort
        return eventsByDay.map { date, events in
            // Sort events: all-day first, then by start time
            let sortedEvents = events.sorted { event1, event2 in
                // All-day events come first
                if event1.isAllDay && !event2.isAllDay {
                    return true
                } else if !event1.isAllDay && event2.isAllDay {
                    return false
                }
                // Within same type, sort by start time
                return event1.startDate < event2.startDate
            }

            return DayEvents(date: date, events: sortedEvents)
        }
        .sorted { $0.date < $1.date }
    }
}

#Preview {
    CKCompactAgenda(
        detail: { _ in EmptyView() },
        events: testEvents
    )
}

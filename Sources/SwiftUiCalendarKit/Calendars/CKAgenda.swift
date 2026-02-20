//
//  SwiftUIView.swift
//  SwiftUiCalendarKit
//
//  Created by Mark Haskins on 20/02/2026.
//

import SwiftUI

public struct CKAgenda: View {

    @Environment(\.ckConfig)
    private var config

    @ObservedObject var observer: CKCalendarObserver

    private let events: [any CKEventSchema]

    private let calendar = Calendar.current

    public init(
        observer: CKCalendarObserver,
        events: [any CKEventSchema]
    ) {
        self._observer = .init(wrappedValue: observer)
        self.events = events
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(groupedEvents) { dayEvents in
                    agendaDaySection(dayEvents: dayEvents)
                        .padding([.top, .bottom], 16)

                    if dayEvents.id != groupedEvents.last?.id {
                        Divider()
                            .padding(.horizontal)
                    }
                }
            }
            .padding(.top, 16)
        }
    }
    
    @ViewBuilder
    private func agendaDaySection(dayEvents: DayEvents) -> some View {

        HStack(alignment: .top, spacing: 16) {
            // Left side: Day number and name
            HStack(spacing: 20) {
                Text(dayEvents.date.formatted(.dateTime.day()))
                    .font(.system(size: 56, weight: .regular, design: .default))
                    .foregroundStyle(.primary)

                VStack(alignment: .leading) {
                    Text(dayEvents.date.formatted(.dateTime.weekday(.wide)))
                        .font(.body)
                        .foregroundStyle(.primary)

                    Text(dayEvents.date.formatted(.dateTime.month(.abbreviated).year()))
                        .font(.body)
                        .foregroundStyle(.primary)
                }
            }
            .frame(width: 200)
            .padding(.trailing,50)

            // Right side: Events
            VStack(alignment: .leading, spacing: 12) {
                // Show multi-day events first
                ForEach(dayEvents.multiDayEvents, id: \.anyHashableID) { event in
                    multiDayEventView(event: event, date: dayEvents.date)
                }
                
                // Show single-day events
                ForEach(dayEvents.singleDayEvents, id: \.anyHashableID) { event in
                    singleDayEventView(event: event)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal)
    }
    
    @ViewBuilder
    private func multiDayEventView(event: any CKEventSchema, date: Date) -> some View {

        HStack(spacing: 12) {
            // Show when it ends
            VStack(alignment: .leading, spacing: 0) {
                Text("Ends \(event.endDate.formatted(.dateTime.day().month(.abbreviated)))")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
            .frame(width: 200, alignment: .leading)

            // Multi-day event banner
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
        }
        .frame(width: .infinity, alignment: .leading)
        .onTapGesture {
            observer.eventSelected = true
            observer.event = event
        }
    }
    
    @ViewBuilder
    private func singleDayEventView(event: any CKEventSchema) -> some View {
        HStack(alignment: .top, spacing: 12) {
            // Time range
            VStack(alignment: .leading, spacing: 0) {
                if event.isAllDay {
                    Text("All Day")
                        .font(.body)
                        .foregroundStyle(.primary)
                } else {
                    Text("\(event.startDate.formatted(.dateTime.hour().minute())) - \(event.endDate.formatted(.dateTime.hour().minute()))")
                        .font(.body)
                        .foregroundStyle(.primary)
                }
            }
            .frame(width: 200, alignment: .leading)

            // Event indicator and title
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
        }
        .frame(width: .infinity, alignment: .leading)
        .onTapGesture {
            observer.eventSelected = true
            observer.event = event
        }
    }
}

// MARK: - Data Grouping
extension CKAgenda {

    private struct DayEvents: Identifiable {
        let id = UUID()
        let date: Date
        let multiDayEvents: [any CKEventSchema]
        let singleDayEvents: [any CKEventSchema]
    }

    private var groupedEvents: [DayEvents] {
        var eventsByDay: [Date: (multiDay: [any CKEventSchema], singleDay: [any CKEventSchema])] = [:]

        // Process each event and add it to all days it spans
        for event in events {
            let startDay = calendar.startOfDay(for: event.startDate)
            let endDay = calendar.startOfDay(for: event.endDate)
            
            let isMultiDay = startDay != endDay

            // For multi-day events, add to each day in the range
            var currentDay = startDay
            while currentDay <= endDay {
                if eventsByDay[currentDay] == nil {
                    eventsByDay[currentDay] = ([], [])
                }

                eventsByDay[currentDay]?.singleDay.append(event)

                // Move to next day
                guard let nextDay = calendar.date(byAdding: .day, value: 1, to: currentDay) else {
                    break
                }
                currentDay = nextDay
            }
        }

        // Convert to array and sort
        return eventsByDay.map { date, events in
            // Sort events by start time
            let sortedMultiDay = events.multiDay.sorted { $0.startDate < $1.startDate }
            let sortedSingleDay = events.singleDay.sorted { event1, event2 in
                // All-day events come first
                if event1.isAllDay && !event2.isAllDay {
                    return true
                } else if !event1.isAllDay && event2.isAllDay {
                    return false
                }
                // Within same type, sort by start time
                return event1.startDate < event2.startDate
            }

            return DayEvents(date: date, multiDayEvents: sortedMultiDay, singleDayEvents: sortedSingleDay)
        }
        .sorted { $0.date < $1.date }
    }
}

#Preview {
    CKAgenda(
        observer: CKCalendarObserver(),
        events: testEvents,
    )
}

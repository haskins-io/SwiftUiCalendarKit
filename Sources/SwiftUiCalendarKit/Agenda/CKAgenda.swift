//
//  SwiftUIView.swift
//  SwiftUiCalendarKit
//
//  Created by Mark Haskins on 20/02/2026.
//

import SwiftUI

/// `CKAgenda` can be used for showing an ordered list of events
///
///     CKAgenda(
///         observer: CKCalendarObserver(),
///         events: events
///     )
///
/// - Parameter observer: Listen to this to be notified when an event is tapped/clicked
/// - Parameter events: the projected ``CKEvent``s to show. Every kind is drawn .


public struct CKAgenda: View {

    @Environment(\.ckConfig)
    private var config

    @Environment(\.colorScheme)
    private var colorScheme

    @State var observer: CKCalendarObserver

    private let events: [CKEvent]

    private let calendar = Calendar.current

    /// The first day the list covers, when the caller has one.
    private let from: Date?

    private let celestial: [Date: [CKEvent]]

    /// Bumped by the toolbar's Today button.
    @State private var scrollRequest = 0

    public init(
        observer: CKCalendarObserver,
        events: [CKEvent],
        from: Date? = nil,
        celestial: [Date: [CKEvent]] = [:],
        scrollRequest: Int = 0
    ) {
        self._observer = .init(wrappedValue: observer)
        self.events = events
        self.from = from
        self.celestial = celestial
        self.scrollRequest = scrollRequest
    }

    public var body: some View {
        VStack {
            CKAgendaToday(scrollRequest: $scrollRequest)

            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(self.groupedEvents) { dayEvents in
                            self.agendaDaySection(dayEvents: dayEvents)
                                .padding([.top, .bottom], 16)
                                .id(dayEvents.id)

                            if dayEvents.id != self.groupedEvents.last?.id {
                                Divider()
                                    .padding(.horizontal)
                            }
                        }
                    }
                    .padding(.top, 16)
                }
                .onChange(of: self.scrollRequest) {
                    guard let target = self.todaysSection else {
                        return
                    }

                    withAnimation {
                        proxy.scrollTo(target, anchor: .top)
                    }
                }
            }
        }
        .background(colorScheme == .dark ? Color.black : Color.white)
    }

    /// The first section on or after today — which is where "Today" should land even when today
    /// itself holds nothing.
    private var todaysSection: Date? {
        let today = Date().midnight

        return self.groupedEvents.first { $0.date >= today }?.id
    }

    @ViewBuilder
    private func agendaDaySection(dayEvents: DayEvents) -> some View {

        HStack(alignment: .top, spacing: 16) {
            // Left side: Day number and name
            HStack(spacing: 20) {
                Text(dayEvents.date.formatted(.dateTime.day()))
                    .font(.largeTitle)
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
            .frame(width: 175)
            .padding(.trailing, 15)

            // Right side: Events
            VStack(alignment: .leading, spacing: 12) {
                // Bands first — they set the context the rest of the day sits inside
                ForEach(dayEvents.multiDayEvents) { event in
                    self.multiDayEventView(event: event)
                }

                ForEach(dayEvents.singleDayEvents) { event in
                    self.singleDayEventView(event: event)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal)
    }

    @ViewBuilder
    private func multiDayEventView(event: CKEvent) -> some View {

        HStack(spacing: 12) {
            // Show when it ends
            VStack(alignment: .leading, spacing: 0) {
                Text("Ends \(event.endDate.formatted(.dateTime.day().month(.abbreviated)))")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
            .frame(width: 175, alignment: .leading)

            self.eventLabel(event: event)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(.rect)
        .onTapGesture { self.observer.event = event }
    }

    @ViewBuilder
    private func singleDayEventView(event: CKEvent) -> some View {
        HStack(alignment: .top, spacing: 12) {
            // Time range
            VStack(alignment: .leading, spacing: 0) {
                self.timeLabel(event: event)
                    .font(.body)
                    .foregroundStyle(.primary)
            }
            .frame(width: 175, alignment: .leading)

            self.eventLabel(event: event)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(.rect)
        .onTapGesture { self.observer.event = event }
    }

    /// The left-hand column, which is the only place the four kinds read differently.
    @ViewBuilder
    private func timeLabel(event: CKEvent) -> some View {
        switch event.kind {
        case .timed(let start, let end):
            Text("\(start.formatted(.dateTime.hour().minute())) - \(end.formatted(.dateTime.hour().minute()))")

        case .allDay:
            Text("All Day")

        case .deadline(let at):
            // No range: a deadline has no duration, and printing "12:00 - 12:00" was the
            // list-shaped version of drawing it zero pixels high (§3.4).
            Text("Due \(at.formatted(.dateTime.hour().minute()))")

        case .span(_, let through):
            Text("Until \(through.formatted(.dateTime.day().month(.abbreviated)))")
        }
    }

    @ViewBuilder
    private func eventLabel(event: CKEvent) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                if !event.systemImage.isEmpty {
                    Image(systemName: event.systemImage)
                }

                Text(event.title)
                    .font(.subheadline)
            }
            .font(.body)

            if let subtitle = event.subtitle {
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(event.tint.opacity(event.isTentative ? 0.15 : 0.3))
        .overlay {
            HStack {
                Rectangle()
                    .fill(event.tint)
                    .frame(maxHeight: .infinity, alignment: .leading)
                    .frame(width: 4)
                Spacer()
            }
        }
    }
}

// MARK: - Data Grouping
extension CKAgenda {

    private struct DayEvents: Identifiable {
        let id: Date
        var date: Date { self.id }
        let multiDayEvents: [CKEvent]
        let singleDayEvents: [CKEvent]
    }

    private var groupedEvents: [DayEvents] {

        let grouped = Dictionary(grouping: self.events) { self.bucket(for: $0) }

        return grouped
            .map { date, events in
                let bands = events.filter { $0.isMultiDay(in: self.calendar) }
                let rest = events.filter { !$0.isMultiDay(in: self.calendar) }

                return DayEvents(
                    id: date,
                    multiDayEvents: bands.sorted { $0.startDate < $1.startDate },
                    singleDayEvents: rest.sorted(by: CKAgenda.byLaneThenStart)
                )
            }
            .sorted { $0.date < $1.date }
    }

    /// Which day an event is listed under — once each, on the day it begins. See the note on
    /// `CKCompactAgenda.bucket(for:)` for why listing a band on every day it covers is wrong in
    /// a list even though it is right in a grid.
    private func bucket(for event: CKEvent) -> Date {
        guard let from else {
            return self.calendar.startOfDay(for: event.startDate)
        }

        return max(self.calendar.startOfDay(for: event.startDate), self.calendar.startOfDay(for: from))
    }

    /// All-day first, then the timed events in order, then the day's deadlines.
    ///
    /// A deadline sorts last rather than by its time of day on purpose: it is not a slot in the
    /// day's schedule, it is something the day is carrying.
    private static func byLaneThenStart(_ lhs: CKEvent, _ rhs: CKEvent) -> Bool {
        func rank(_ event: CKEvent) -> Int {
            switch event.kind {
            case .allDay:
                0

            case .timed, .span:
                1

            case .deadline:
                2
            }
        }

        if rank(lhs) != rank(rhs) {
            return rank(lhs) < rank(rhs)
        }

        return lhs.startDate < rhs.startDate
    }
}

#Preview {
    CKAgenda(
        observer: CKCalendarObserver(),
        events: testEvents
    )
}

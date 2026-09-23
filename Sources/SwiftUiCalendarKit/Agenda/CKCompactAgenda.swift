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
/// - Parameter events: the projected ``CKEvent``s to show.

public struct CKCompactAgenda<Detail: View>: View {

    @Environment(\.ckConfig)
    private var config

    @Environment(\.colorScheme)
    private var colorScheme

    private let detail: (CKEvent) -> Detail
    private let events: [CKEvent]

    private let calendar = Calendar.current

    /// The first day the list covers, when the caller has one.
    private let from: Date?


    /// §7 — the gated half of the footer, bucketed by day.
    private let celestial: [Date: [CKEvent]]

    /// Bumped by the toolbar's Today button — see `CKAgenda`.
    @State private var scrollRequest = 0

    public init(
        @ViewBuilder detail: @escaping (CKEvent) -> Detail,
        events: [CKEvent],
        from: Date? = nil,
        celestial: [Date: [CKEvent]] = [:],
        scrollRequest: Int = 0
    ) {
        self.detail = detail
        self.events = events
        self.from = from
        self.celestial = celestial
        self.scrollRequest = scrollRequest
    }

    public var body: some View {
        VStack {
            CKAgendaToday(scrollRequest: $scrollRequest)
            ScrollViewReader { proxy in
                self.list
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

    /// The first section on or after today — where "Today" lands even when today holds nothing.
    private var todaysSection: Date? {
        let today = Date().midnight

        return self.groupedEvents.first { $0.date >= today }?.id
    }

    @ViewBuilder private var list: some View {
        List {
            ForEach(self.groupedEvents) { dayEvents in
                Section {
                    ForEach(dayEvents.events) { event in
                        NavigationLink {
                            self.detail(event)
                        } label: {
                            self.agendaEventRow(event: event)
                        }
                        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                    }
                } header: {
                    self.agendaSectionHeader(date: dayEvents.date)
                }
                .id(dayEvents.id)
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

                Spacer(minLength: 8)
            }
            .font(.subheadline)
            .textCase(nil)
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private func agendaEventRow(event: CKEvent) -> some View {
        HStack(alignment: .top, spacing: 12) {
            // Time column
            VStack(alignment: .trailing, spacing: 0) {
                self.timeLabel(event: event)
            }
            .frame(width: 50, alignment: .trailing)

            // Event details
            VStack(alignment: .leading, spacing: 2) {
                HStack {

                    if !event.systemImage.isEmpty {
                        Image(systemName: event.systemImage)
                    }

                    Text(event.title)
                        .font(.subheadline)
                        .padding(.leading, 5)
                }
                .font(.body)

                if let subtitle = event.subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.leading, 5)
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

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
    }

    /// The narrow left column. A deadline prints one time, not a range — see `CKAgenda`.
    @ViewBuilder
    private func timeLabel(event: CKEvent) -> some View {
        switch event.kind {
        case .timed(let start, let end):
            Text(start.formatted(.dateTime.hour().minute()))
                .font(.caption)

            Text(end.formatted(.dateTime.hour().minute()))
                .font(.caption)
                .foregroundStyle(.secondary)

        case .allDay:
            Text("All-Day")
                .font(.caption)
                .foregroundStyle(.secondary)

        case .deadline(let at):
            Text(at.formatted(.dateTime.hour().minute()))
                .font(.caption)

            Text("due")
                .font(.caption2)
                .foregroundStyle(.secondary)

        case .span(_, let through):
            Text("to")
                .font(.caption2)
                .foregroundStyle(.secondary)

            Text(through.formatted(.dateTime.day().month(.abbreviated)))
                .font(.caption)
        }
    }
}

// MARK: - Data Grouping
extension CKCompactAgenda {

    private struct DayEvents: Identifiable {
        let id: Date
        var date: Date { self.id }
        let events: [CKEvent]
    }

    private var groupedEvents: [DayEvents] {

        let grouped = Dictionary(grouping: self.events) { self.bucket(for: $0) }

        return grouped
            .map { date, events in
                DayEvents(id: date, events: events.sorted(by: CKCompactAgenda.byLaneThenStart))
            }
            .sorted { $0.date < $1.date }
    }

    /// Which day an event is listed under.
    private func bucket(for event: CKEvent) -> Date {
        guard let from else {
            return self.calendar.startOfDay(for: event.startDate)
        }

        return max(self.calendar.startOfDay(for: event.startDate), self.calendar.startOfDay(for: from))
    }

    /// All-day and spanning events first, then the timed ones in order, then the deadlines.
    private static func byLaneThenStart(_ lhs: CKEvent, _ rhs: CKEvent) -> Bool {
        func rank(_ event: CKEvent) -> Int {
            switch event.kind {
            case .allDay, .span:
                0

            case .timed:
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
    CKCompactAgenda(
        detail: { _ in EmptyView() },
        events: testEvents
    )
}


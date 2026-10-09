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

    @Environment(\.locale)
    private var locale

    @Environment(\.ckConfig)
    private var config

    @Environment(\.colorScheme)
    private var colorScheme

    private let detail: (CKEvent) -> Detail
    private let events: [CKEvent]

    private let calendar = Calendar.current

    /// The first day the list covers, when the caller has one.
    private let from: Date?

    /// Bumped by the toolbar's Today button — see `CKAgenda`.
    @State private var scrollRequest = 0

    public init(
        @ViewBuilder detail: @escaping (CKEvent) -> Detail,
        events: [CKEvent],
        from: Date? = nil,
        scrollRequest: Int = 0
    ) {
        self.detail = detail
        self.events = events
        self.from = from
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
        CKAgendaSections.todaysSection(in: self.groupedEvents)
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
                Text(date.formatted(.dateTime.weekday(.wide).locale(self.locale)))
                Text(date.formatted(.dateTime.day().month(.abbreviated).locale(self.locale)))

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
            Text(start.formatted(.dateTime.hour().minute().locale(self.locale)))
                .font(.caption)

            Text(end.formatted(.dateTime.hour().minute().locale(self.locale)))
                .font(.caption)
                .foregroundStyle(.secondary)

        case .allDay:
            Text(CKStrings.allDay.locale(self.locale))
                .font(.caption)
                .foregroundStyle(.secondary)

        case .deadline(let at):
            let time = Self.emphasised(at.formatted(.dateTime.hour().minute().locale(self.locale)))

            Text(AttributedString(localized: CKStrings.compactDue(time).locale(self.locale)))
            .font(.caption2)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.trailing)

        case .span(_, let through):
            let day = Self.emphasised(through.formatted(.dateTime.day().month(.abbreviated).locale(self.locale)))

            Text(AttributedString(localized: CKStrings.compactUntil(day).locale(self.locale)))
            .font(.caption2)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.trailing)
        }
    }

    /// The time or date in a two-line label, set apart from the word beside it as the two
    /// separate labels used to be: `.caption` in the primary colour, against `.caption2` in
    /// the secondary.
    private static func emphasised(_ text: String) -> AttributedString {
        var emphasised = AttributedString(text)
        emphasised.font = .caption
        emphasised.foregroundColor = .primary
        return emphasised
    }
}

// MARK: - Data Grouping
extension CKCompactAgenda {

    private var groupedEvents: [CKAgendaDay] {
        CKAgendaSections.days(events: self.events, from: self.from, calendar: self.calendar)
    }
}

#Preview {
    CKCompactAgenda(
        detail: { _ in EmptyView() },
        events: testEvents
    )
}

/// Laid out and formatted as for an Arabic reader: right to left, with Arabic digits, months and
/// weekdays. The package's own words stay English until it has an Arabic translation.
#Preview("Arabic, right to left") {
    CKCompactAgenda(
        detail: { _ in EmptyView() },
        events: testEvents
    )
    .environment(\.locale, Locale(identifier: "ar"))
    .environment(\.layoutDirection, .rightToLeft)
}

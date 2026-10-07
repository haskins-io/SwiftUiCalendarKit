//
//  CKCompactMonth.swift
//
//  Created by Mark Haskins on 09/04/2024.
//

import SwiftUI

/// `CKCompactMonth` can be used for showing a single day calendar on a compact screen size such as an iPhone.
///
///     CKCompactMonth(
///         detail: { event in EventDetail(event: event) },
///         events: events,
///         date: $date
///     )
///
/// - Parameter detail: The view that should be shown when an event in the Calendar is tapped.
/// - Parameter events: an array of events that conform to ``CKEvent``.
/// - Parameter date: The date for the calendar to show.

public struct CKCompactMonth<Detail: View>: View {

    @Environment(\.colorScheme)
    private var colorScheme

    @Binding private var date: Date

    private let detail: (CKEvent) -> Detail
    private var events: [CKEvent]

    public init(
        @ViewBuilder detail: @escaping (CKEvent) -> Detail,
        events: [CKEvent],
        date: Binding<Date>,
    ) {
        self.detail = detail
        self.events = events
        self._date = date
    }

    public var body: some View {
        VStack {
            CKMonthComponent(calendar: Calendar.current, date: $date, events: events)

            CKCompactMonthEvents(events: events, detail: detail, date: $date)
                .listStyle(.plain)
        }
        .background(colorScheme == .dark ? Color.black : Color.white)
    }
}

#Preview {
    NavigationView {
        CKCompactMonth(
            detail: { _ in EmptyView() },
            events: testEvents,
            date: .constant(Date())
        )
    }
}

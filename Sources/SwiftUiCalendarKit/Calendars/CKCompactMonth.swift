//
//  CKCompactMonth.swift
//
//  Created by Mark Haskins on 09/04/2024.
//

import SwiftUI

///
/// CKCompactMonth
///
/// This Calendar type is used for showing a month on a compact screen size such as an iPhone
///
/// - Paramters
///   - detail: The view that should be shown when an event in the Calendar is tapped.
///   - events: an array of events that conform to CKEventSchema
///   - date: The date for the calendar to show
///
public struct CKCompactMonth<Detail: View>: View {

    @Binding private var date: Date

    private let detail: (any CKEventSchema) -> Detail

    private var events: [any CKEventSchema]

    public init(
        @ViewBuilder detail: @escaping (any CKEventSchema) -> Detail,
        events: [any CKEventSchema],
        date: Binding<Date>
    ) {
        self.detail = detail
        self.events = events
        self._date = date
    }

    public var body: some View {
        VStack {
            CKMonthComponent(calendar: Calendar.current, date: $date, events: events)
            Divider()
            CKCompactMonthEvents(events: events, detail: detail, date: $date)
                .listStyle(.plain)
        }
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

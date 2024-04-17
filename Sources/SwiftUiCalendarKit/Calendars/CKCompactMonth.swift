//
//  CalendarCompactMonth.swift
//  freya
//
//  Created by Mark Haskins on 09/04/2024.
//

import SwiftUI

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
            CKMonthComponent(calendar: Calendar(identifier: .gregorian), date: $date, events: events)
            Divider()
            CKCompantMonthEvents(events: events, detail: detail, date: $date)
                .listStyle(.plain)
        }
    }
}

#Preview {
    NavigationView {

        let event1 = CKEvent(
            startDate: Date().dateFrom(16, 4, 2024, 1, 00),
            endDate: Date().dateFrom(16, 4, 2024, 2, 00),
            text: "Event 1",
            backCol: "#D74D64"
        )

        let event2 = CKEvent(
            startDate: Date().dateFrom(16, 4, 2024, 2, 00),
            endDate: Date().dateFrom(16, 4, 2024, 3, 00),
            text: "Event 2",
            backCol: "#3E56C2"
        )

        let event3 = CKEvent(
            startDate: Date().dateFrom(16, 4, 2024, 3, 30),
            endDate: Date().dateFrom(16, 4, 2024, 4, 30),
            text: "Event 3",
            backCol: "#F6D264"
        )

        CKCompactMonth(
            detail: { event in EmptyView() },
            events: [event1, event2, event3],
            date: .constant(Date().dateFrom(16, 4, 2024))
        )
    }
}

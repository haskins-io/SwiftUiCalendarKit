//
//  CKCompactMonthEvents.swift
//  
//
//  Created by Mark Haskins on 14/04/2024.
//

import SwiftUI

struct CKCompactMonthEvents<Detail: View>: View {

    @Binding private var date: Date

    let calendar = Calendar.current

    private let detail: (any CKEventSchema) -> Detail
    private var events: [any CKEventSchema]

    init(
        events: [any CKEventSchema],
        @ViewBuilder detail: @escaping (any CKEventSchema) -> Detail,
        date: Binding<Date>
    ) {
        self.detail = detail
        self.events = events
        self._date = date
    }

    var body: some View {

        List {

            ForEach(events, id: \.anyHashableID) { event in

                if calendar.isDate(event.startDate, inSameDayAs: date) {
                    NavigationLink(destination: detail(event)) {
                        CKListEventView(event: event)
                    }
                }
            }
        }
        .listStyle(.plain)
    }
}

#Preview {
    CKCompactMonthEvents(
        events: testEvents,
        detail: { _ in EmptyView() },
        date: .constant(Date())
    )
}

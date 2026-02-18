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
                if listEvent(event: event) {
                    NavigationLink(destination: detail(event)) {
                        CKListEventView(event: event)
                    }
                }
            }
        }
        .listStyle(.plain)
    }

    private func listEvent(event: any CKEventSchema) -> Bool {

        let start = event.startDate.midnight
        let dayAfter = calendar.date(byAdding: .day, value: 1, to: event.endDate)?.midnight ?? event.endDate.midnight
        let end = calendar.date(byAdding: .minute, value: -1, to: dayAfter) ?? dayAfter

        let eventRange = start...end

        if calendar.isDate(event.startDate, inSameDayAs: date) ||
            eventRange.contains(date) {

            return true
        }

        return false
    }
}

#Preview {
    CKCompactMonthEvents(
        events: testEvents,
        detail: { _ in EmptyView() },
        date: .constant(Date())
    )
}

//
//  File.swift
//  
//
//  Created by Mark Haskins on 14/04/2024.
//

import SwiftUI

struct CKCompantMonthEvents<Detail: View>: View {

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
    CKCompantMonthEvents (
        events: [
            CKEvent(startDate: Date().dateFrom(13, 4, 2024, 12, 00), endDate: Date().dateFrom(13, 4, 2024, 13, 00), text: "Event 1"),
            CKEvent(startDate: Date().dateFrom(13, 4, 2024, 12, 15), endDate: Date().dateFrom(13, 4, 2024, 13, 15), text: "Event 2"),
            CKEvent(startDate: Date().dateFrom(13, 4, 2024, 12, 30), endDate: Date().dateFrom(13, 4, 2024, 15, 01), text: "Event 3"),
        ],
        detail: { event in EmptyView() },
        date: .constant(Date().dateFrom(13, 4, 2024))
    )
}

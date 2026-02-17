//
//  CKCompactEventsView.swift
//  SwiftUiCalendarKit
//
//  Created by Mark Haskins on 17/02/2026.
//

import SwiftUI

struct CKCompactEventsView<Detail: View>: View {

    var date: Date
    var eventData: [CKEventViewData]
    var detail: (any CKEventSchema) -> Detail

    var body: some View {
        ForEach(eventData, id: \.anyHashableID) { event in
            if calendar.isDate(event.event.startDate, inSameDayAs: date) && !event.allDay {
                CKCompactEventView(
                    event,
                    detail: detail
                )
            }
        }
    }
}

#Preview {
    CKCompactEventsView(
        date: Date(),
        eventData: [],
        detail: { _ in EmptyView() }
    )
}

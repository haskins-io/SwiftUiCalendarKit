//
//  SwiftUIView.swift
//  SwiftUiCalendarKit
//
//  Created by Mark Haskins on 17/02/2026.
//

import SwiftUI

struct CKCompactDayEventsView<Detail: View>: View {

    var date: Date
    var eventData: [CKEventViewData]
    var detail: (any CKEventSchema) -> Detail

    var body: some View {
        VStack(spacing: 0) {
            ForEach(eventData, id: \.anyHashableID) { event in
                if calendar.isDate(event.event.startDate, inSameDayAs: date) && event.allDay {
                    CKCompactDayEventView(
                        event,
                        detail: detail
                    )
                }
            }
        }
    }
}

#Preview {
    CKCompactDayEventsView(
        date: Date(),
        eventData: [CKEventViewData(
            event: CKEvent(
                startDate: Date(),
                endDate: Date(),
                isAllDay: true,
                text: "Event 1",
                backCol: "#D74D64"),
            overlapsWith: 1,
            position: 1,
            width: 150
        )],
        detail: { _ in EmptyView() }
    )
}

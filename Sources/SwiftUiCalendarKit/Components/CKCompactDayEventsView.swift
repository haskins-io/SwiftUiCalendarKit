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

                if showEvent(event: event.event) {
                    CKCompactDayEventView(event, detail: detail)
                }
            }
        }
    }

    private func showEvent(event: CKEventSchema) -> Bool {
        if event.isAllDay && CKUtils.doesEventOccurOnDate(event: event, date: date) {
            return true
        }

        return false
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

//
//  CKDayEventView.swift
//
//  Created by Mark Haskins on 15/02/2026.
//

import SwiftUI

struct CKDayEventView: View {

    @ObservedObject var observer: CKCalendarObserver

    private let eventData: CKEventViewData
    private let event: any CKEventSchema

    init(_ eventData: CKEventViewData,
         observer: CKCalendarObserver
    ) {
        self.eventData = eventData
        self._observer = .init(wrappedValue: observer)

        self.event = eventData.event
    }

    var body: some View {
        VStack {
            Text(event.text).bold().padding(.leading, 5)
        }
        .foregroundColor(.primary)
        .font(.caption)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(4)
        .background(.thinMaterial)
        .background(
            RoundedRectangle(cornerRadius: 3)
                .fill(event.backgroundAsColor()).opacity(0.5)
                .shadow(radius: 5, x: 2, y: 5)
        )
        .onTapGesture {
            observer.eventSelected = true
            observer.event = event
        }
    }
}

#Preview {
    CKDayEventView(
        CKEventViewData(
            event: CKEvent(
                startDate: Date().dateFrom(13, 4, 2024, 1, 00),
                endDate: Date().dateFrom(13, 4, 2024, 2, 00),
                isAllDay: true,
                text: "Event 1",
                backCol: "#D74D64"),
            overlapsWith: 1,
            position: 1,
            width: 150
        ),
        observer: CKCalendarObserver()
    )
}

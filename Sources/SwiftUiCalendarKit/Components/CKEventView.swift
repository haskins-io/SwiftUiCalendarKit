//
//  SwiftUIView.swift
//  
//
//  Created by Mark Haskins on 12/04/2024.
//

import SwiftUI

struct CKEventView: View {

    private let eventData: CKEventViewData

    private let xOffset: CGFloat

    private let event: any CKEventSchema

    @ObservedObject var observer: CKCalendarObserver

    init(_ eventData: CKEventViewData,
         observer: CKCalendarObserver,
         weekView: Bool
    ) {
        self.eventData = eventData
        self._observer = .init(wrappedValue: observer)

        self.event = eventData.event

        var dayOfWeek = Date.dayOfWeek(event.startDate)
        if dayOfWeek == 1 {
            dayOfWeek = 8
        }

        if weekView {

            // WeekTimeline
            if eventData.position > 1 {
                let edgeOfDayCell = 47 + (eventData.cellWidth * CGFloat(dayOfWeek - 1))
                xOffset = (edgeOfDayCell + ((eventData.position - 1) * (eventData.eventWidth + 5)))
            } else {
                if dayOfWeek == 1 {
                    xOffset = 47
                } else {
                    xOffset = 47 + (eventData.cellWidth * CGFloat(dayOfWeek - 2))
                }
            }
        } else {

            // Day Timeline
            if eventData.position > 1 {
                xOffset = 47 + (eventData.eventWidth + 5) * (eventData.position - 1)
            } else {
                xOffset = 47
            }
        }
    }

    var body: some View {

        VStack(alignment: .leading) {
            Text(event.startDate.formatted(.dateTime.hour().minute())).padding(.leading, 5)
            Text(event.text).bold().padding(.leading, 5)
        }
        .foregroundColor(.primary)
        .font(.caption)
        .frame(maxWidth: eventData.eventWidth - 5, alignment: .leading)
        .padding(4)
        .frame(height: eventData.height, alignment: .top)
        .background(.thinMaterial)
        .background(
            RoundedRectangle(cornerRadius: 3)
                .fill(event.backgroundAsColor()).opacity(0.5)
                .shadow(radius: 5, x: 2, y: 5)
        )
        .overlay {
            HStack {
                Rectangle()
                    .fill(event.backgroundAsColor())
                    .frame(maxHeight: .infinity, alignment: .leading)
                    .frame(width: 4)
                Spacer()
            }
        }
        .padding(.trailing, 30)
        .offset(x: xOffset, y: eventData.yOffset + 30)
        .onTapGesture {
            observer.eventSelected = true
            observer.event = event
        }
    }
}

#Preview {
    CKEventView(
        CKEventViewData(
            event: CKEvent(
                startDate: Date().dateFrom(13, 4, 2024, 1, 00),
                endDate: Date().dateFrom(13, 4, 2024, 2, 00),
                text: "Event 1",
                backCol: "#D74D64"),
            overlapsWith: 1,
            position: 1,
            width: 150
        ),
        observer: CKCalendarObserver(),
        weekView: false
    )
}

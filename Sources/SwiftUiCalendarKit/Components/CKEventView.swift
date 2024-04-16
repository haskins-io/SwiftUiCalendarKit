//
//  SwiftUIView.swift
//  
//
//  Created by Mark Haskins on 12/04/2024.
//

import SwiftUI

struct CKEventView: View {

    private let eventData: EventViewData

    private let xOffset: CGFloat

    private let event: any CKEventSchema

    @ObservedObject var observer: CKCalendarObserver

    init(_ eventData: EventViewData,
         observer: CKCalendarObserver,
         weekView: Bool)
    {

        self.eventData = eventData
        self._observer = .init(wrappedValue: observer)

        self.event = eventData.event

        let dayOfWeek = Date.dayOfWeek(event.startDate)

        if weekView {

            // WeekTimeline
            if eventData.position > 1 {
                let edgeOfDayCell = 47 + (eventData.cellWidth * CGFloat(dayOfWeek - 1))
                xOffset = (edgeOfDayCell + ((eventData.position - 1) * (eventData.eventWidth + 5)))
            } else {
                if dayOfWeek == 1 {
                    xOffset = 47
                } else {
                    xOffset = 47 + (eventData.cellWidth * CGFloat(dayOfWeek - 1))
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
            Text(event.startDate.formatted(.dateTime.hour().minute()))
            Text(event.text).bold()
        }
        .font(.caption)
        .foregroundColor(event.textAsColor())
        .frame(maxWidth: eventData.eventWidth - 5, alignment: .leading)
        .padding(4)
        .frame(height: eventData.height, alignment: .top)
        .background(
            RoundedRectangle(cornerRadius: 3)
                .fill(event.backgroundAsColor()).opacity(0.8)
        )
        .padding(.trailing, 30)
        .offset(x: xOffset, y: eventData.yOffset + 30)
        .onTapGesture {
            observer.eventSelected = true
            observer.event = event
        }
    }
}

//#Preview {
//    CKEventCell()
//}

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
         applyXOffset: Bool,
         startDay: Int? = 0) 
    {

        self.eventData = eventData
        self._observer = .init(wrappedValue: observer)

        self.event = eventData.event

        if applyXOffset, let start = startDay {
            
            if eventData.position > 1 {
                xOffset = (eventData.eventWidth + 10) * (eventData.position - 1) + 55
            } else {
                xOffset = (CGFloat(eventData.day - start) * eventData.cellWidth) + 46
            }
        } else {
            if eventData.position > 1 {
                xOffset = (eventData.eventWidth + 10) * (eventData.position - 1) + 56
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
        .frame(maxWidth: eventData.eventWidth, alignment: .leading)
        .padding(4)
        .frame(height: eventData.height, alignment: .top)
        .background(
            RoundedRectangle(cornerRadius: 3)
                .fill(.teal).opacity(0.8)
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

//
//  File.swift
//  
//
//  Created by Mark Haskins on 15/04/2024.
//

import SwiftUI

struct CKCompactEventView<Detail: View>: View {

    private let detail: (any CKEventSchema) -> Detail

    private let eventData: EventViewData
    private let xOffset: CGFloat
    private let event: any CKEventSchema


    init(_ eventData: EventViewData,
         @ViewBuilder detail: @escaping (any CKEventSchema) -> Detail,
         applyXOffset: Bool,
         startDay: Int? = 0)
    {
        self.detail = detail

        self.eventData = eventData

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
            NavigationLink {
                detail(event)
            } label: {
                VStack {
                    Text(event.startDate.formatted(.dateTime.hour().minute()))
                    Text(event.text).bold()
                }
                .font(.caption)
                .foregroundColor(event.textAsColor())
                .frame(width: eventData.eventWidth, alignment: .leading)
                .padding(4)
                .frame(height: eventData.height, alignment: .top)
                .background(
                    RoundedRectangle(cornerRadius: 3)
                        .fill(event.backgroundAsColor()).opacity(0.8)
                )
                .padding(.trailing, 30)
            }
        }
        .offset(x: xOffset, y: eventData.yOffset + 30)
    }
}


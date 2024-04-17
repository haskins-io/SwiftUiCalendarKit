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
         @ViewBuilder detail: @escaping (any CKEventSchema) -> Detail)
    {
        self.detail = detail

        self.eventData = eventData

        self.event = eventData.event

        if eventData.position > 1 {
            xOffset = ((eventData.eventWidth + 10) * (eventData.position - 1)) + 46
        } else {
            xOffset = 47
        }
    }

    var body: some View {

        VStack {
            NavigationLink {
                detail(event)
            } label: {
                VStack(alignment: .leading) {
                    Text(event.startDate.formatted(.dateTime.hour().minute())).padding(.leading, 5)
                    Text(event.text).bold().padding(.leading, 5)
                }
                .font(.caption)
                .frame(width: eventData.eventWidth, alignment: .leading)
                .padding(4)
                .frame(height: eventData.height, alignment: .top)
                .background(.thinMaterial)
                .background(
                    RoundedRectangle(cornerRadius: 5)
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
            }
        }
        .offset(x: xOffset, y: eventData.yOffset + 30)
    }
}

#Preview {
    CKCompactEventView(
        EventViewData(
            event: CKEvent(
                startDate: Date().dateFrom(13, 4, 2024, 1, 00),
                endDate: Date().dateFrom(13, 4, 2024, 2, 00),
                text: "Event 1",
                backCol: "#D74D64"),
            overlapsWith: 1,
            position: 1,
            width: 150
        ),
        detail: { event in EmptyView() }
    )
}


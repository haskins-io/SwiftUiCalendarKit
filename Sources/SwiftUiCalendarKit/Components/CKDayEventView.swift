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

    private var xOffset: CGFloat = 0
    private var isWeekView = false
    private var width: CGFloat = 0

    init(_ eventData: CKEventViewData,
         observer: CKCalendarObserver,
         weekView: Bool,
         width: CGFloat
    ) {
        self.eventData = eventData
        self._observer = .init(wrappedValue: observer)

        self.isWeekView = weekView
        self.event = eventData.event
        self.width = width

        var dayOfWeek = Date.dayOfWeek(event.startDate)
        if dayOfWeek == 1 {
            dayOfWeek = 8
        }

        if weekView {
            if dayOfWeek == 1 {
                xOffset = 50
            } else {
                xOffset = 50 + (eventData.cellWidth * CGFloat(dayOfWeek - 2))
            }
        }
    }

    var body: some View {
        VStack {
            Text(event.text).bold().padding(.leading, 5)
        }
        .foregroundColor(.primary)
        .font(.caption)
        .frame(maxWidth: width, alignment: .leading)
        .padding(6)
        .background(.thinMaterial)
        .background(
            RoundedRectangle(cornerRadius: 3)
                .fill(event.backgroundAsColor())
                .opacity(0.5)
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
        .offset(x: xOffset, y: 0)
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
                startDate: Date(),
                endDate: Date(),
                isAllDay: true,
                text: "Event 1",
                backCol: "#D74D64"),
            overlapsWith: 0,
            position: 1,
            width: 150
        ),
        observer: CKCalendarObserver(),
        weekView: true,
        width: 150
    )
}

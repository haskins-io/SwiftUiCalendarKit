//
//  SwiftUIView.swift
//  SwiftUiCalendarKit
//
//  Created by Mark Haskins on 18/02/2026.
//

import SwiftUI

struct CKTimelineWeekEventView: View {

    @ObservedObject var observer: CKCalendarObserver

    private var eventData: CKEventViewData
    private let event: any CKEventSchema
    private let xOffset: CGFloat

    init(_ eventData: CKEventViewData,
         observer: CKCalendarObserver
    ) {
        self.eventData = eventData
        self._observer = .init(wrappedValue: observer)
        self.event = eventData.event

        if eventData.position > 1 {
            xOffset = (eventData.eventWidth * (eventData.position - 1)) + 7
        } else {
            xOffset = 0
        }
    }

    var body: some View {
        if Calendar.current.differenceInMinutes(start: event.startDate, end: event.endDate) >= 30 {
            greaterThan30mins()
        } else {
            lessThan30mins()
        }
    }

    @ViewBuilder
    private func greaterThan30mins() -> some View {
        VStack(alignment: .leading) {
            Text(event.startDate.formatted(.dateTime.hour().minute())).padding(.leading, 5)
            Text(event.text).bold().padding(.leading, 5)
        }
        .foregroundColor(.primary)
        .font(.caption)
        .frame(maxWidth: eventData.eventWidth - 7, alignment: .leading)
        .padding(4)
        .frame(height: eventData.height, alignment: .top)
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
        .padding(.trailing, 5)
        .offset(x: xOffset, y: eventData.yOffset + 30)
        .onTapGesture {
            observer.eventSelected = true
            observer.event = event
        }
    }

    @ViewBuilder
    private func lessThan30mins() -> some View {
        HStack(alignment: .center) {
            Text(event.startDate.formatted(.dateTime.hour().minute())).padding(.leading, 5)
            Text(event.text).bold()
        }
        .foregroundColor(.primary)
        .font(.caption)
        .frame(maxWidth: eventData.eventWidth - 7, alignment: .leading)
        .padding(4)
        .frame(height: eventData.height, alignment: .top)
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
        .padding(.trailing, 5)
        .offset(x: xOffset, y: eventData.yOffset + 30)
        .onTapGesture {
            observer.eventSelected = true
            observer.event = event
        }
    }
}

#Preview {
    CKTimelineWeekEventView(
        CKEventViewData(
            event: CKEvent(
                startDate: Date().dateFrom(13, 4, 2024, 1, 00),
                endDate: Date().dateFrom(13, 4, 2024, 2, 00),
                isAllDay: false,
                text: "Event 1",
                backCol: "#D74D64"),
            overlapsWith: 1,
            position: 1,
            width: 150
        ),
        observer: CKCalendarObserver()
    )
}

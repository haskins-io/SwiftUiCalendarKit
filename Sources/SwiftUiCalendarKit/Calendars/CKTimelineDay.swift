//
//  SingleTimeline.swift
//  freya
//
//  Created by Mark Haskins on 03/04/2024.
//

import SwiftUI

public struct CKTimelineDay: View {

    @ObservedObject var observer: CKCalendarObserver

    @Binding private var date: Date

    private var events: [any CKEventSchema]

    private let calendar = Calendar(identifier: .gregorian)

    public init(observer: CKCalendarObserver, events: [any CKEventSchema], date: Binding<Date>) {
        self._observer = .init(wrappedValue: observer)
        self.events = events
        self._date = date
    }

    public var body: some View {

        GeometryReader { proxy in

            VStack(alignment: .leading) {

                HStack {
                    Text(date.formatted(.dateTime.day().month(.wide)))
                        .bold()
                    Text(date.formatted(.dateTime.year()))
                }
                .padding(.leading, 10)
                .padding(.top, 5)
                .font(.title)

                Text(date.formatted(.dateTime.weekday(.wide))).padding(.leading, 10)

                Divider().padding([.leading, .trailing], 10)

                ScrollView {

                    ZStack(alignment: .topLeading) {

                        CKTimeline()

                        ForEach(events, id: \.anyHashableID) { event in

                            if calendar.isDate(event.startDate, inSameDayAs: date) {

                                let overlapping = CKUtils.overLappingEventsCount(event, events)

                                CKEventCell(
                                    event,
                                    overLapping: overlapping,
                                    observer: observer,
                                    width: (proxy.size.width - 70),
                                    applyXOffset: false
                                )
                            }
                        }
                    }
                }
            }
            .background(Color.white)
        }
    }
}

#Preview {
    CKTimelineDay(
        observer: CKCalendarObserver(),
        events: [
            CKEvent(startDate: Date().dateFrom(13, 4, 2024, 12, 00), endDate: Date().dateFrom(13, 4, 2024, 13, 00), text: "Date 1"),
            CKEvent(startDate: Date().dateFrom(13, 4, 2024, 12, 30), endDate: Date().dateFrom(13, 4, 2024, 13, 30), text: "Date 2"),
            CKEvent(startDate: Date().dateFrom(13, 4, 2024, 15, 00), endDate: Date().dateFrom(13, 4, 2024, 16, 00), text: "Date 3"),
        ],
        date: .constant(Date().dateFrom(13, 4, 2024))
    )
}

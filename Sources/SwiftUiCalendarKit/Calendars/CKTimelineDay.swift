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

                        let eventData = CKUtils.generateEventViewData(
                            date: date,
                            events: events,
                            width: proxy.size.width - 65
                        )

                        ForEach(eventData, id: \.self) { event in
                            CKEventView(
                                event,
                                observer: observer,
                                applyXOffset: false
                            )
                        }
                    }
                }
            }
            .background(Color.white)
        }
    }
}

#Preview {

    let event1 = CKEvent(
        startDate: Date().dateFrom(13, 4, 2024, 12, 00),
        endDate: Date().dateFrom(13, 4, 2024, 13, 00),
        text: "Event 1",
        backCol: "#D74D64"
    )

    let event2 = CKEvent(
        startDate: Date().dateFrom(13, 4, 2024, 12, 15),
        endDate: Date().dateFrom(13, 4, 2024, 13, 15),
        text: "Event 2",
        backCol: "#3E56C2"
    )

    let event3 = CKEvent(
        startDate: Date().dateFrom(13, 4, 2024, 12, 30),
        endDate: Date().dateFrom(13, 4, 2024, 15, 01),
        text: "Event 3",
        backCol: "#F6D264"
    )

    return CKTimelineDay(
        observer: CKCalendarObserver(),
        events: [event1, event2, event3],
        date: .constant(Date().dateFrom(13, 4, 2024))
    )
}

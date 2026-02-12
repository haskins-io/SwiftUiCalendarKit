//
//  CalendarWeekView.swift
//  freya
//
//  Created by Mark Haskins on 09/04/2024.
//

import SwiftData
import SwiftUI

public struct CKTimelineWeek: View {

    @ObservedObject var observer: CKCalendarObserver

    @Binding var date: Date

    private var events: [any CKEventSchema]

    private let calendar = Calendar.current

    private let properties: CKProperties

    public init(
        observer: CKCalendarObserver,
        events: [any CKEventSchema],
        date: Binding<Date>,
        props: CKProperties? = CKProperties()
    ) {
        self._observer = .init(wrappedValue: observer)
        self.events = events
        self._date = date
        self.properties = props ?? CKProperties()
    }

    public var body: some View {

        GeometryReader { proxy in

            VStack(alignment: .leading) {

                CKCalendarHeader(currentDate: $date, addWeek: true)

                CKDayHeader(currentDate: $date, width: proxy.size.width, showTime: true, showDate: true)

                Divider()

                timeline(proxy: proxy)
            }
        }
    }

    @ViewBuilder
    private func timeline(proxy: GeometryProxy) -> some View {

        ScrollView {

            ZStack(alignment: .topLeading) {
                
                CKTimeline(props: properties)

                let eventData = CKUtils.generateEventViewData(
                    date: date,
                    events: events,
                    width: ((proxy.size.width - CGFloat(55)) / 7)
                )

                ForEach(eventData, id: \.anyHashableID) { event in
                    CKEventView(
                        event,
                        observer: observer,
                        weekView: true
                    )
                }

                ForEach(1..<7) { day in

                    let offset: CGFloat = ((proxy.size.width - CGFloat(55)) / CGFloat(7)) * CGFloat(day)

                    Rectangle()
                        .fill(Color.gray)
                        .frame(width: 1,
                               height: 1460,
                               alignment: .center)
                        .offset(x: offset + 45, y: 10)
                }
            }
        }
        if #available(iOS 17, macOS 14, *) {
            self.defaultScrollAnchor(.center)
        }
    }
}

#Preview {

    let event1 = CKEvent(
        startDate: Date().dateFrom(14, 4, 2024, 1, 00),
        endDate: Date().dateFrom(14, 4, 2024, 2, 00),
        text: "Event 1",
        backCol: "#D74D64"
    )

    let event2 = CKEvent(
        startDate: Date().dateFrom(15, 4, 2024, 2, 00),
        endDate: Date().dateFrom(15, 4, 2024, 3, 00),
        text: "Event 2",
        backCol: "#3E56C2"
    )

    let event3 = CKEvent(
        startDate: Date().dateFrom(16, 4, 2024, 3, 30),
        endDate: Date().dateFrom(16, 4, 2024, 4, 30),
        text: "Event 3",
        backCol: "#F6D264"
    )

    return CKTimelineWeek(
        observer: CKCalendarObserver(),
        events: [event1, event2, event3],
        date: .constant(Date().dateFrom(16, 4, 2024))
    )
}

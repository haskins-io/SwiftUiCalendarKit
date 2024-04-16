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

    private let calendar = Calendar(identifier: .gregorian)

    public init(observer: CKCalendarObserver, events: [any CKEventSchema], date: Binding<Date>) {
        self._observer = .init(wrappedValue: observer)
        self.events = events
        self._date = date
    }

    public var body: some View {

        GeometryReader { proxy in

            VStack(alignment: .leading) {

                CKCalendarHeader(currentDate: $date, addWeek: true)

                CKDayHeader(currentDate: $date, width: proxy.size.width, showTime: true, showDate: true)

                Divider()

                timeline(proxy: proxy)
            }
            .background(Color.white)
        }
    }

    private func timeline(proxy: GeometryProxy) -> some View {

        return ScrollView {

            ZStack(alignment: .topLeading) {
                
                CKTimeline()

                let eventData = CKUtils.generateEventViewData(
                    date: date,
                    events: events,
                    width: ((proxy.size.width - CGFloat(90)) / 7)
                )

                ForEach(eventData, id: \.self) { event in
                    CKEventView(
                        event,
                        observer: observer,
                        applyXOffset: false,
                        startDay: calendar.firstDateOfWeek(week: date)
                    )
                }

                ForEach(1..<7) { day in

                    let offset: CGFloat = ((proxy.size.width - CGFloat(40)) / CGFloat(7)) * CGFloat(day)

                    Rectangle()
                        .fill(Color.gray)
                        .frame(width: 1,
                               height: 1460,
                               alignment: .center)
                        .offset(x: offset + 45, y: 10)
                }
            }
        }
    }
}

#Preview {

    let event1 = CKEvent(
        startDate: Date().dateFrom(16, 4, 2024, 12, 00),
        endDate: Date().dateFrom(16, 4, 2024, 13, 00),
        text: "Event 1",
        backCol: "#D74D64"
    )

    let event2 = CKEvent(
        startDate: Date().dateFrom(16, 4, 2024, 12, 15),
        endDate: Date().dateFrom(16, 4, 2024, 13, 15),
        text: "Event 2",
        backCol: "#3E56C2"
    )

    let event3 = CKEvent(
        startDate: Date().dateFrom(16, 4, 2024, 12, 30),
        endDate: Date().dateFrom(16, 4, 2024, 15, 01),
        text: "Event 3",
        backCol: "#F6D264"
    )

    return CKTimelineWeek(
        observer: CKCalendarObserver(),
        events: [event1, event2, event3],
        date: .constant(Date().dateFrom(16, 4, 2024))
    )
}

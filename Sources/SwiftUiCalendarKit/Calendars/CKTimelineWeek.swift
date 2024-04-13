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

                ForEach(events, id: \.anyHashableID) { event in

                    let overlapping = CKUtils.overLappingEventsCount(event, events)

                    CKEventCell(
                        event,
                        overLapping: overlapping,
                        observer: observer,
                        width: ((proxy.size.width - CGFloat(40)) / 7),
                        applyXOffset: true,
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
    CKTimelineWeek(
        observer: CKCalendarObserver(),
        events: [
            CKEvent(startDate: Date().dateFrom(13, 4, 2024, 12, 00), endDate: Date().dateFrom(13, 4, 2024, 13, 00), text: "Date 1"),
            CKEvent(startDate: Date().dateFrom(14, 4, 2024, 12, 30), endDate: Date().dateFrom(14, 4, 2024, 13, 30), text: "Date 2"),
            CKEvent(startDate: Date().dateFrom(15, 4, 2024, 15, 00), endDate: Date().dateFrom(15, 4, 2024, 16, 00), text: "Date 3"),
        ],
        date: .constant(Date().dateFrom(13, 4, 2024))
    )
}

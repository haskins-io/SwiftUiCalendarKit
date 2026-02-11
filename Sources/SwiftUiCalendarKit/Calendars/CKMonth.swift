//
//  CalendarMonthView.swift
//  freya
//
//  Created by Mark Haskins on 09/04/2024.
//

import SwiftUI

public struct CKMonth: View {

    @ObservedObject var observer: CKCalendarObserver

    @Binding var date: Date

    private let calendar = Calendar.current

    private var events: [any CKEventSchema]

    public init(observer: CKCalendarObserver, events: [any CKEventSchema], date: Binding<Date>) {
        self._observer = .init(wrappedValue: observer)
        self.events = events
        self._date = date
    }

    public var body: some View {

        GeometryReader { proxy in

            VStack(alignment: .leading, spacing: 0) {

                CKCalendarHeader(currentDate: $date, addWeek: false)
                    .padding(.bottom, 5)

                CKDayHeader(currentDate: $date, width: proxy.size.width, showTime: false, showDate: false)
                    .padding(.bottom, 5)

                Divider()

                monthGrid(proxy: proxy)
            }
            .padding(0)
        }
    }

    private func monthGrid(proxy: GeometryProxy) -> some View {

        let cellWidth = proxy.size.width / 7
        let cellHeight = ((proxy.size.height - 70) / 6) + 4

        let days = makeDays()
        let month = date.startOfMonth(using: calendar)

        return LazyVGrid(columns: Array(repeating: GridItem(), count: 7), spacing: 0) {

            ForEach(days, id: \.self) { day in
                CKMonthDayCell(
                    date: day,
                    observer: observer,
                    events: eventsForDay(day: day),
                    month: month,
                    width: cellWidth,
                    height: cellHeight
                )
            }
        }
        .padding(0)
    }

    private func makeDays() -> [Date] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: date),
              let monthFirstWeek = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.start),
              let monthLastWeek = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.end - 1)
        else {
            return []
        }

        let dateInterval = DateInterval(start: monthFirstWeek.start, end: monthLastWeek.end)
        return calendar.generateDays(for: dateInterval)
    }

    private func eventsForDay(day: Date) -> [any CKEventSchema] {
        
        var dayEvents: [any CKEventSchema] = []

        for event in events {
            if Calendar.current.isDate(event.startDate, inSameDayAs: day) {
                dayEvents.append(event)
            }
        }

        return dayEvents
    }
}

#Preview {


    let event1 = CKEvent(
        startDate: Date().dateFrom(3, 2, 2026, 1, 00),
        endDate: Date().dateFrom(3, 2, 2026, 2, 00),
        text: "Event 1",
        backCol: "#D74D64"
    )

    let event2 = CKEvent(
        startDate: Date().dateFrom(3, 2, 2026, 2, 00),
        endDate: Date().dateFrom(3, 2, 2026, 3, 00),
        text: "Event 2"
    )

    let event3 = CKEvent(
        startDate: Date().dateFrom(3, 2, 2026, 3, 30),
        endDate: Date().dateFrom(3, 2, 2026, 4, 30),
        text: "Event 3",
        backCol: "#F6D264"
    )

    return CKMonth(
        observer: CKCalendarObserver(),
        events: [event1, event2, event3],
        date: .constant(Date().dateFrom(11, 2, 2026))
    )
}

//
//  CalendarMonthView.swift
//  freya
//
//  Created by Mark Haskins on 09/04/2024.
//

import SwiftUI

public struct CKMonth: View {

    @State var currentDay = Date()
    private let calendar = Calendar(identifier: .gregorian)

    private var events: [any CKEventSchema]

    public init(events: [any CKEventSchema]) {
        self.events = events
    }

    public var body: some View {

        GeometryReader { proxy in
            VStack(alignment: .leading) {
                CKCalendarHeader(currentDate: $currentDay, addWeek: false)
                CKDayHeader(currentDate: $currentDay, width: proxy.size.width, showTime: false, showDate: false)

                Divider()

                monthGrid(proxy: proxy)
            }
            .background(Color.white)
            .padding(0)
        }
    }

    private func monthGrid(proxy: GeometryProxy) -> some View {

        let cellWidth = proxy.size.width / 7
        let cellHeight = (proxy.size.height - 100) / 6

        let days = makeDays()
        let month = currentDay.startOfMonth(using: calendar)

        return LazyVGrid(columns: Array(repeating: GridItem(), count: 7), spacing: 0) {
            ForEach(days, id: \.self) { date in
                CKMonthDayCell(
                    date: date,
                    events: eventsForDay(day: date),
                    month: month,
                    width: cellWidth,
                    height: cellHeight
                )
            }
        }
        .padding(0)
    }

    private func makeDays() -> [Date] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: currentDay),
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
    CKMonth(events: [])
}

//
//  CKMonth.swift
//
//  Created by Mark Haskins on 09/04/2024.
//

import SwiftUI

///
/// CKCompactMonth
///
/// This Calendar type is used for showing a week on a large screen size such as an iPad or Mac
///
/// - Paramters
///   - observer: Listen to this to be notified when an event is tapped/clicked
///   - events: an array of events that conform to CKEventSchema
///   - date: The date for the calendar to show
///
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

        for event in events where calendar.isDate(event.startDate, inSameDayAs: day) {
            dayEvents.append(event)
        }

        return dayEvents
    }
}

#Preview {
    return CKMonth(
        observer: CKCalendarObserver(),
        events: testEvents,
        date: .constant(Date())
    )
}

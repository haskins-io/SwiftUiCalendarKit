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

    @Binding var calendarDate: Date

    @State private var calendarWidth: CGFloat = .zero
    @State private var calendarHeight: CGFloat = .zero

    private let calendar = Calendar.current

    private var events: [any CKEventSchema]

    public init(observer: CKCalendarObserver, events: [any CKEventSchema], date: Binding<Date>) {
        self._observer = .init(wrappedValue: observer)
        self.events = events
        self._calendarDate = date
    }

    public var body: some View {

        GeometryReader { geometry in

            Color.clear
                .onChange(of: geometry.size) { _, newSize in
                    guard newSize.width > 0, newSize.height > 0 else {
                        return
                    }

                    calendarWidth = newSize.width
                    calendarHeight = newSize.height
                }

            if calendarWidth != 0 {
                VStack(alignment: .leading, spacing: 0) {

                    CKCalendarHeader(currentDate: $calendarDate, addWeek: false)
                        .padding(.bottom, 5)

                    CKDayHeader(currentDate: $calendarDate, width: calendarWidth, showTime: false, showDate: false)
                        .padding(.bottom, 5)

                    Divider()

                    monthGrid()
                }
                .padding(0)
            }
        }
    }

    @ViewBuilder
    private func monthGrid() -> some View {

        let cellWidth = calendarWidth / 7
        let cellHeight = ((calendarHeight - 70) / 6) + 4

        let days = makeDays()
        let month = calendarDate.startOfMonth(using: calendar)

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
}

extension CKMonth {

    private func makeDays() -> [Date] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: calendarDate),
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

        for event in events where calendar.isDate(event.startDate, inSameDayAs: day) ||
        CKUtils.doesEventOccurOnDate(event: event, date: day) {

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

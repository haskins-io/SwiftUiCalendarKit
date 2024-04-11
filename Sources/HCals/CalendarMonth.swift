//
//  CalendarMonthView.swift
//  freya
//
//  Created by Mark Haskins on 09/04/2024.
//

import SwiftUI

struct CalendarMonth: View {

    @State var currentDay = Date()
    private let calendar = Calendar(identifier: .gregorian)

    var body: some View {

        GeometryReader { proxy in
            VStack(alignment: .leading) {
                CalendarHeader(currentDate: $currentDay, addWeek: false)
                DayHeader(currentDate: $currentDay, width: proxy.size.width, showTime: false, showDate: false)

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
                MonthDayCell(date: date, month: month, width: cellWidth, height: cellHeight)
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
}

#Preview {
    CalendarMonth()
}

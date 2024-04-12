//
//  Calendar.swift
//  SwiftUiCalendars
//
//  Created by Mark Haskins on 11/04/2024.
//

import Foundation

extension Calendar {

    /// - Used to Store Data of Each Week Day
    struct WeekDay: Identifiable {
        var id: UUID = .init()
        var string: String
        var date: Date
        var isToday = false
    }

    /// - Returns 24 Hours in a day
    var hours: [Date] {
        let startOfDay = self.startOfDay(for: Date())

        var hours: [Date] = []

        for index in 0..<24 {
            if let date = self.date(byAdding: .hour, value: index, to: startOfDay) {
                hours.append(date)
            }
        }

        return hours
    }

    /// - Returns Current Week in Array Format
    func currentWeek(today: Date) -> [WeekDay] {

        guard let firstWeekDay = self.dateInterval(of: .weekOfMonth, for: today)?.start else {
            return []
        }

        var week: [WeekDay] = []

        for index in 0..<7 {
            if let day = self.date(byAdding: .day, value: index, to: firstWeekDay) {
                let weekDaySymbol: String = day.toString("EEEE")
                let isToday = self.isDateInToday(day)
                week.append(.init(string: weekDaySymbol, date: day, isToday: isToday))
            }
        }

        return week
    }

    func firstDateOfWeek(week: Date) -> Int {

        guard let firstWeekDay = self.dateInterval(of: .weekOfMonth, for: week)?.start else {
            return 0
        }
        
        let components = dateComponents([.day], from: firstWeekDay)
        return components.day ?? 0
    }

    func generateDates(
        for dateInterval: DateInterval,
        matching components: DateComponents
    ) -> [Date] {
        var dates = [dateInterval.start]

        enumerateDates(
            startingAfter: dateInterval.start,
            matching: components,
            matchingPolicy: .nextTime
        ) { date, _, stop in
            guard let date = date else {
                return
            }

            guard date < dateInterval.end else {
                stop = true
                return
            }

            dates.append(date)
        }

        return dates
    }

    func generateDays(for dateInterval: DateInterval) -> [Date] {
        generateDates(
            for: dateInterval,
            matching: dateComponents([.hour, .minute, .second], from: dateInterval.start)
        )
    }
}

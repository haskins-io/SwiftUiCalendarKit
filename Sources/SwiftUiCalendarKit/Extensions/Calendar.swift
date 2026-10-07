//
//  Calendar.swift
//
//  Created by Mark Haskins on 11/04/2024.
//

import Foundation

extension Calendar {

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
            guard let date, date < dateInterval.end, dates.count < 42 else {
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

    /// The days a month grid draws for the month containing `date`.
    ///
    /// Whole weeks, from the one holding the 1st to the one holding the last day, and no
    /// further — so a month that ends on the last day of a week is five rows, not six.
    ///
    /// `CKMonth` and the compact grid's `CalendarComponent` each had their own copy of this,
    /// which is how one fix would otherwise have had to be made twice.
    func monthGridDays(for date: Date) -> [Date] {
        guard let month = dateInterval(of: .month, for: date),
              let firstWeek = dateInterval(of: .weekOfMonth, for: month.start),
              let lastWeek = dateInterval(of: .weekOfMonth, for: month.end - 1)
                else {
            return []
        }

        return generateDays(for: DateInterval(start: firstWeek.start, end: lastWeek.end))
    }

    func differenceInMinutes(start: Date, end: Date) -> Int {
        return dateComponents([.minute], from: start, to: end).minute ?? 30
    }

    func weekOfYear(currentDate: Date) -> Int {
        return dateComponents([.weekOfYear], from: currentDate).weekOfYear ?? -1
    }
}

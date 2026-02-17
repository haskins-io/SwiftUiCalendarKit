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

        var count = 0

        enumerateDates(
            startingAfter: dateInterval.start,
            matching: components,
            matchingPolicy: .nextTime
        ) { date, _, stop in
            guard let date = date else {
                return
            }

            guard count < 41 else {
                stop = true
                return
            }

            dates.append(date)

            count += 1
        }

        return dates
    }

    func generateDays(for dateInterval: DateInterval) -> [Date] {
        generateDates(
            for: dateInterval,
            matching: dateComponents([.hour, .minute, .second], from: dateInterval.start)
        )
    }

    func differenceInMinutes(start: Date, end: Date) -> Int {
        return dateComponents([.minute], from: start, to: end).minute ?? 30
    }
}

//
//  Date.swift
//
//  Created by Mark Haskins on 11/04/2024.
//

import Foundation

nonisolated extension Date {

    var midnight: Date {
        let cal = Calendar.current
        return cal.startOfDay(for: self)
    }

    /// The week containing this date, from its first day to the same time seven days later.
    /// Where the week starts is `calendar`'s choice.
    func fetchWeekRange(in calendar: Calendar) -> ClosedRange<Date> {

        let startOfWeek = calendar.dateInterval(of: .weekOfMonth, for: self)?.start ?? Date()
        let endOfWeek = calendar.date(byAdding: .day, value: 7, to: startOfWeek) ?? Date()

        return startOfWeek...endOfWeek
    }

    /// The last representable instant of this day.
    ///
    /// The counterpart to `midnight`, and the closing bound for anything that occupies whole
    /// days rather than hours — `CKEvent.Kind.allDay` and `.span` both end here. One second
    /// before the next midnight rather than the next midnight itself, so a day-long event does
    /// not read as touching the day after it.
    var endOfDay: Date {
        let cal = Calendar.current
        let nextMidnight = cal.date(byAdding: .day, value: 1, to: self.midnight) ?? self
        return cal.date(byAdding: .second, value: -1, to: nextMidnight) ?? self
    }

    /// Whether this instant falls on today's date in the reader's calendar.
    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }

    /// The day as a whole, for asking which band or marker events touch it.
    var dayInterval: DateInterval {
        DateInterval(start: self.midnight, end: self.endOfDay)
    }

    /// The first instant of the month containing this date, in `calendar`. A Hebrew or Islamic
    /// month begins on a different day from a Gregorian one.
    func startOfMonth(in calendar: Calendar) -> Date {
        calendar.date(
            from: calendar.dateComponents([.year, .month], from: self)
        ) ?? Date()
    }

    static func dayOfWeek(_ date: Date) -> Int {
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.weekday], from: date)
        return dateComponents.weekday ?? 0
    }

    func previousDate() -> Date {
        let calendar = Calendar.current
        guard let date = calendar.date(byAdding: .day, value: -1, to: self) else {
            return Date()
        }

        return date
    }

    func nextDate() -> Date {
        let calendar = Calendar.current
        guard let date = calendar.date(byAdding: .day, value: 1, to: self) else {
            return Date()
        }

        return date
    }

    /// The seven days of the week containing this date, starting on `calendar`'s first weekday.
    func fetchWeek(in calendar: Calendar) -> [WeekDay] {
        return fetchWeek(self, in: calendar)
    }

    func fetchWeek(_ date: Date, in calendar: Calendar) -> [WeekDay] {

        guard let startOfWeek = calendar.dateInterval(of: .weekOfMonth, for: date)?.start else {
            return []
        }

        var week: [WeekDay] = []

        (0..<7).forEach { index in
            if let weekDay = calendar.date(byAdding: .day, value: index, to: startOfWeek) {
                week.append(.init(date: weekDay, isToday: weekDay.isToday))
            }
        }

        return week
    }

    /// The week after the one ending on this date.
    func createNextWeek(in calendar: Calendar) -> [WeekDay] {
        let startOfLastDate = calendar.startOfDay(for: self)
        guard let nextDate = calendar.date(byAdding: .day, value: 1, to: startOfLastDate) else {
            return []
        }

        return fetchWeek(nextDate, in: calendar)
    }

    /// The week before the one starting on this date.
    func createPreviousWeek(in calendar: Calendar) -> [WeekDay] {
        let startOfFirstDate = calendar.startOfDay(for: self)
        guard let previousDate = calendar.date(byAdding: .day, value: -1, to: startOfFirstDate) else {
            return []
        }

        return fetchWeek(previousDate, in: calendar)
    }
}

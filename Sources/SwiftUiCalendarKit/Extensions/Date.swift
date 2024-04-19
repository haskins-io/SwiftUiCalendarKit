//
//  Date.swift
//  SwiftUiCalendars
//
//  Created by Mark Haskins on 11/04/2024.
//

import Foundation

extension Date {

    /// - Used to Store Data of Each Week Day
    struct WeekDay: Identifiable {
        var id: UUID = .init()
        var string: String
        var date: Date
        var isToday = false
    }

    var isToday: Bool {
        return Calendar.current.isDateInToday(self)
    }

    // This is only used to create Test dates, and Preview dates
    public func dateFrom(_ day: Int, _ month: Int, _ year: Int, _ hour: Int = 0, _ minute: Int = 0) -> Date {
        let calendar = Calendar.current
        let dateComponents = DateComponents(year: year, month: month, day: day, hour: hour, minute: minute)
        return calendar.date(from: dateComponents) ?? .now
    }

    func startOfMonth(using calendar: Calendar) -> Date {
        calendar.date(
            from: calendar.dateComponents([.year, .month], from: self)
        ) ?? self
    }

    static func dayOfWeek(_ date: Date) -> Int {
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.weekday], from: date)
        return dateComponents.weekday ?? 0
    }

    func toString(_ format: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        return formatter.string(from: self)
    }

    func fetchWeek(_ date: Date = .init()) -> [WeekDay] {

        let calendar = Calendar.current

        guard let startOfWeek = calendar.dateInterval(of: .weekOfMonth, for: date)?.start else {
            return []
        }

        var week: [WeekDay] = []
        
        (0..<7).forEach { index in
            if let weekDay = calendar.date(byAdding: .day, value: index, to: startOfWeek) {
                let weekDaySymbol: String = weekDay.toString("EEEE")
                week.append(.init(string: weekDaySymbol, date: weekDay, isToday: weekDay.isToday))
            }
        }

        return week
    }

    func createNextWeek() -> [WeekDay] {
        let calendar = Calendar.current
        let startOfLastDate = calendar.startOfDay(for: self)
        guard let nextDate = calendar.date(byAdding: .day, value: 1, to: startOfLastDate) else {
            return []
        }

        return fetchWeek(nextDate)
    }

    func createPreviousWeek() -> [WeekDay] {
        let calendar = Calendar.current
        let startOfFirstDate = calendar.startOfDay(for: self)
        guard let previousDate = calendar.date(byAdding: .day, value: -1, to: startOfFirstDate) else {
            return []
        }

        return fetchWeek(previousDate)
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
}

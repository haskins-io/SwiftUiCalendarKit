//
//  Date.swift
//  SwiftUiCalendars
//
//  Created by Mark Haskins on 11/04/2024.
//

import Foundation

extension Date {

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
}

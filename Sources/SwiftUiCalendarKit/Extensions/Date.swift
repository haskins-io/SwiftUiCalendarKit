//
//  Date.swift
//  SwiftUiCalendars
//
//  Created by Mark Haskins on 11/04/2024.
//

import Foundation

extension Date {

    func startOfMonth(using calendar: Calendar) -> Date {
        calendar.date(
            from: calendar.dateComponents([.year, .month], from: self)
        ) ?? self
    }

    func toString(_ format: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        return formatter.string(from: self)
    }
}

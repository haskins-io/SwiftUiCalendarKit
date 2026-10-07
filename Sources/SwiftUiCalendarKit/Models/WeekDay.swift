//
//  File.swift
//  SwiftUiCalendarKit
//
//  Created by Mark Haskins on 18/02/2026.
//

import Foundation

/// - Used to Store Data of Each Week Day
struct WeekDay: Identifiable {
    var date: Date
    var string: String
    var isToday = false

    var id: Date { self.date }
}

//
//  File.swift
//  SwiftUiCalendarKit
//
//  Created by Mark Haskins on 18/02/2026.
//

import Foundation

/// - Used to Store Data of Each Week Day
struct WeekDay: Identifiable {
    var id: UUID = .init()
    var string: String
    var date: Date
    var isToday = false
    }

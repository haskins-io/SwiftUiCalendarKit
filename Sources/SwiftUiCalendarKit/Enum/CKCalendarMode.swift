//
//  CalendarMode.swift
//  SwiftUiCalendars
//
//  Created by Mark Haskins on 11/04/2024.
//

import SwiftUI

public enum CKCalendarMode: String, CaseIterable, Identifiable {
    public var id: Self { self }
    case day
    case week
    case month
}

extension CKCalendarMode {

    var label: String {
        switch self {
        case .day:
            return "Day"
        case .week:
            return "Week"
        case .month:
            return "Month"
        }
    }
}

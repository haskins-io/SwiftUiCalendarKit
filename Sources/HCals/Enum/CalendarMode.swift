//
//  CalendarMode.swift
//  SwiftUiCalendars
//
//  Created by Mark Haskins on 11/04/2024.
//

import SwiftUI

enum CalendarMode: String, CaseIterable, Identifiable {
    var id: Self { self }
    case day
    case week
    case month
}

extension CalendarMode {

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

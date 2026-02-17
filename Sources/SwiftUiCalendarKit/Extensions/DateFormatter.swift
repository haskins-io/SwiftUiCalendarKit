//
//  DateFormatter.swift
//
//  Created by Mark Haskins on 11/04/2024.
//

import Foundation

extension DateFormatter {

    convenience init(dateFormat: String, calendar: Calendar) {
        self.init()
        self.dateFormat = dateFormat
        self.calendar = calendar
    }
}

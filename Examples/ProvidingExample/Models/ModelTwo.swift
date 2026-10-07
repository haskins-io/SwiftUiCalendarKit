//
//  File.swift
//  SwiftUiCalendarKit
//
//  Created by Mark Haskins on 23/09/2026.
//

import Foundation
import SwiftData

@Model
final class ModelTwo {

    var title: String  = ""
    var startDate = Date()
    var endDate   = Date()
    var isAllDay  = false
    var colour: Colour
}

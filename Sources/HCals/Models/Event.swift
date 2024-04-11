//
//  Event.swift
//  SwiftUiCalendars
//
//  Created by Mark Haskins on 11/04/2024.
//

import Foundation

struct Event: Identifiable {

    let id = UUID()

    let startDate: Date
    let endDate: Date
    let title: String
    let detail: String
}

//
//  File.swift
//  SwiftUiCalendarKit
//
//  Created by Mark Haskins on 16/02/2026.
//

import Foundation

let middleDateStart = Date()
let middleDateEnd = Calendar.current.date(byAdding: .hour, value: 1, to: middleDateStart) ?? middleDateStart

let midEventStart = Calendar.current.date(byAdding: .day, value: 1, to: middleDateStart) ??  Date()
let midEventEnd = Calendar.current.date(byAdding: .day, value: 1, to: middleDateEnd) ??  Date()

let testEvents: [any CKEventSchema] = [
    CKEvent(
        startDate: Calendar.current.date(byAdding: .day, value: -2, to: middleDateStart) ??  Date(),
        endDate: Calendar.current.date(byAdding: .day, value: -2, to: middleDateEnd) ??  Date(),
        isAllDay: false,
        text: "Event 1",
        backCol: "#FCE2E3"
    ),
    CKEvent(
        startDate: Calendar.current.date(byAdding: .day, value: -1, to: middleDateStart) ??  Date(),
        endDate: Calendar.current.date(byAdding: .day, value: -1, to: middleDateEnd) ??  Date(),
        isAllDay: false,
        text: "Event 2",
        backCol: "#FBF4D8"
    ),
    CKEvent(
        startDate: middleDateStart,
        endDate: middleDateEnd,
        isAllDay: false,
        text: "Event 3",
        backCol: "#CFD4C5"
    ),
    CKEvent(
        startDate: Calendar.current.date(byAdding: .hour, value: -5, to: midEventStart) ??  Date(),
        endDate: Calendar.current.date(byAdding: .hour, value: -4, to: midEventEnd) ??  Date(),
        isAllDay: false,
        text: "Event 4",
        backCol: "#E2ECE9"
    ),
    CKEvent(
        startDate: Calendar.current.date(byAdding: .hour, value: -2, to: midEventStart) ??  Date(),
        endDate: Calendar.current.date(byAdding: .hour, value: -1, to: midEventEnd) ??  Date(),
        isAllDay: false,
        text: "Event 5",
        backCol: "#ACB2C1"
    ),
    CKEvent(
        startDate: midEventStart,
        endDate: midEventEnd,
        isAllDay: false,
        text: "Event 6",
        backCol: "#E5E4F2"
    ),
    CKEvent(
        startDate: Calendar.current.date(byAdding: .hour, value: 2, to: midEventStart) ??  Date(),
        endDate: Calendar.current.date(byAdding: .hour, value: 3, to: midEventEnd) ??  Date(),
        isAllDay: false,
        text: "Event 7",
        backCol: "#E8D9E7"
    ),
    CKEvent(
        startDate: Calendar.current.date(byAdding: .hour, value: 3, to: midEventStart) ??  Date(),
        endDate: Calendar.current.date(byAdding: .hour, value: 4, to: midEventEnd) ??  Date(),
        isAllDay: false,
        text: "Event 8",
        backCol: "#998CA2"
    ),
    CKEvent(
        startDate: Calendar.current.date(byAdding: .day, value: 2, to: middleDateStart) ??  Date(),
        endDate: Calendar.current.date(byAdding: .day, value: 2, to: middleDateEnd) ??  Date(),
        isAllDay: false,
        text: "Event 9",
        backCol: "#A6C6DD"
    ),
    CKEvent(
        startDate: Calendar.current.date(byAdding: .day, value: 3, to: middleDateStart) ??  Date(),
        endDate: Calendar.current.date(byAdding: .day, value: 3, to: middleDateEnd) ??  Date(),
        isAllDay: false,
        text: "Event 10",
        backCol: "#93B3A7"
    ),
    CKEvent(
        startDate: Calendar.current.date(byAdding: .day, value: 4, to: middleDateStart) ??  Date(),
        endDate: Calendar.current.date(byAdding: .day, value: 4, to: middleDateEnd) ??  Date(),
        isAllDay: false,
        text: "Event 11",
        backCol: "#FFC699"
    )
]

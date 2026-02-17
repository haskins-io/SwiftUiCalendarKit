//
//  SwiftUiCalendarKit.swift
//
//
//  Created by Mark Haskins on 16/04/2024.
//

import SwiftUI

struct ContentView: View {

    @Environment(\.horizontalSizeClass)
    private var horizontalSizeClass

    let calendar = Calendar.current

    static let middleDateStart = Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: Date()) ?? Date()
    static let middleDateEnd = Calendar.current.date(byAdding: .hour, value: 1, to: middleDateStart) ?? Date()

    static let midEventStart = Calendar.current.date(byAdding: .day, value: 1, to: middleDateStart) ?? Date()
    static let midEventEnd = Calendar.current.date(byAdding: .day, value: 1, to: middleDateEnd) ?? Date()

    let testEvents: [any CKEventSchema] = [
        CKEvent(
            startDate: Calendar.current.date(byAdding: .day, value: -4, to: middleDateStart) ?? Date(),
            endDate: Calendar.current.date(byAdding: .day, value: -2, to: middleDateEnd) ?? Date(),
            isAllDay: true,
            text: "Multi Day Event",
            backCol: "#FCE2E3"
        ),
        CKEvent(
            startDate: Calendar.current.date(byAdding: .day, value: -1, to: middleDateStart) ?? Date(),
            endDate: Calendar.current.date(byAdding: .day, value: -1, to: middleDateEnd) ?? Date(),
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
            startDate: middleDateStart,
            endDate: middleDateEnd,
            isAllDay: true,
            text: "All Day 1",
            backCol: "#998CA2"
        ),
        CKEvent(
            startDate: middleDateStart,
            endDate: middleDateEnd,
            isAllDay: true,
            text: "All Day 2",
            backCol: "#E2ECE9"
        ),
        CKEvent(
            startDate: Calendar.current.date(byAdding: .minute, value: -240, to: midEventStart) ?? Date(),
            endDate: Calendar.current.date(byAdding: .minute, value: -318, to: midEventStart) ?? Date(),
            isAllDay: false,
            text: "Event 4",
            backCol: "#E2ECE9"
        ),
        CKEvent(
            startDate: Calendar.current.date(byAdding: .minute, value: -120, to: midEventStart) ?? Date(),
            endDate: Calendar.current.date(byAdding: .minute, value: -100, to: midEventStart) ?? Date(),
            isAllDay: true,
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
            startDate: Calendar.current.date(byAdding: .minute, value: -120, to: midEventStart) ?? Date(),
            endDate: Calendar.current.date(byAdding: .minute, value: -60, to: midEventStart) ?? Date(),
            isAllDay: false,
            text: "Event 7",
            backCol: "#E8D9E7"
        ),
        CKEvent(
            startDate: Calendar.current.date(byAdding: .minute, value: -100, to: midEventStart) ?? Date(),
            endDate: Calendar.current.date(byAdding: .minute, value: -40, to: midEventStart) ?? Date(),
            isAllDay: false,
            text: "Event 8",
            backCol: "#998CA2"
        ),
        CKEvent(
            startDate: Calendar.current.date(byAdding: .minute, value: -80, to: midEventStart) ?? Date(),
            endDate: Calendar.current.date(byAdding: .minute, value: -20, to: midEventStart) ?? Date(),
            isAllDay: false,
            text: "Event 12",
            backCol: "#998CA2"
        ),
        CKEvent(
            startDate: Calendar.current.date(byAdding: .day, value: 2, to: middleDateStart) ?? Date(),
            endDate: Calendar.current.date(byAdding: .day, value: 2, to: middleDateEnd) ?? Date(),
            isAllDay: false,
            text: "Event 9",
            backCol: "#A6C6DD"
        ),
        CKEvent(
            startDate: Calendar.current.date(byAdding: .day, value: 3, to: middleDateStart) ?? Date(),
            endDate: Calendar.current.date(byAdding: .day, value: 3, to: middleDateEnd) ?? Date(),
            isAllDay: false,
            text: "Event 10",
            backCol: "#93B3A7"
        ),
        CKEvent(
            startDate: Calendar.current.date(byAdding: .day, value: 4, to: middleDateStart) ?? Date(),
            endDate: Calendar.current.date(byAdding: .day, value: 4, to: middleDateEnd) ?? Date(),
            isAllDay: false,
            text: "Event 11",
            backCol: "#FFC699"
        )
    ]

    @State private var date = Date()

    @State private var showNewEventSheet = false

    @StateObject private var observer = CKCalendarObserver()

    private var day: some View {
        return CKTimelineDay(
            observer: observer,
            events: events,
            date: $date
        )
    }

    private var dayCompact: some View {
        return CKCompactDay(
            detail: { event in EventDetail(event: event) },
            events: events, date: $date
        )
        .showTime(true)
    }

    private var week: some View {
        CKTimelineWeek(
            observer: observer,
            events: events,
            date: $date
        )
        .showTime(true)
        .workingHours(start: 7, end: 19)
        .currentDayColour(.blue)
    }

    private var weekCompact: some View {
        CKCompactWeek(
            detail: { event in EventDetail(event: event) },
            events: events,
            date: $date
        )
        .currentDayColour(.blue)
    }

    private var month: some View {
        CKMonth(
            observer: observer,
            events: events,
            date: $date
        )
        .currentDayColour(.blue)
    }

    private var monthCompact: some View {
        CKCompactMonth(
            detail: { event in EventDetail(event: event) },
            events: events,
            date: $date
        )
        .currentDayColour(.blue)
    }

    var body: some View {
        NavigationStack {
            dayCompact
        }
    }
}

#Preview {
    ContentView()
}

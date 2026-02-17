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

    //    @Query var events: [Event]
    let events: [any CKEventSchema] = [
        CKEvent(
            startDate: Date().dateFrom(09, 2, 2026, 12, 30),
            endDate: Date().dateFrom(09, 2, 2026, 13, 30),
            text: "Monday",
            backCol: "#D74D64"
        ),
        CKEvent(
            startDate: Date().dateFrom(10, 2, 2026, 12, 30),
            endDate: Date().dateFrom(10, 2, 2026, 13, 30),
            text: "Tuesday",
            backCol: "#D74D64"
        ),
        CKEvent(
            startDate: Date().dateFrom(11, 2, 2026, 13, 00),
            endDate: Date().dateFrom(11, 2, 2026, 14, 00),
            text: "Wednesday",
            backCol: "#3E56C2"
        ),
        CKEvent(
            startDate: Date().dateFrom(12, 2, 2026, 16, 30),
            endDate: Date().dateFrom(12, 2, 2026, 17),
            text: "Thursday",
            backCol: "#F6D264"
        ),
        CKEvent(
            startDate: Date().dateFrom(12, 2, 2026, 16, 30),
            endDate: Date().dateFrom(12, 2, 2026, 17),
            text: "Thursday",
            backCol: "#F6D264"
        ),
        CKEvent(
            startDate: Date().dateFrom(12, 2, 2026, 16, 30),
            endDate: Date().dateFrom(12, 2, 2026, 17),
            text: "Thursday",
            backCol: "#F6D264"
        ),
        CKEvent(
            startDate: Date().dateFrom(12, 2, 2026, 16, 30),
            endDate: Date().dateFrom(12, 2, 2026, 17),
            text: "Thursday",
            backCol: "#F6D264"
        ),
        CKEvent(
            startDate: Date().dateFrom(12, 2, 2026, 16, 30),
            endDate: Date().dateFrom(12, 2, 2026, 17),
            text: "Thursday",
            backCol: "#F6D264"
        ),
        CKEvent(
            startDate: Date().dateFrom(12, 2, 2026, 16, 30),
            endDate: Date().dateFrom(12, 2, 2026, 17),
            text: "Thursday",
            backCol: "#F6D264"
        ),
        CKEvent(
            startDate: Date().dateFrom(13, 2, 2026, 12, 30),
            endDate: Date().dateFrom(13, 2, 2026, 13, 30),
            text: "Friday",
            backCol: "#D74D64"
        ),
        CKEvent(
            startDate: Date().dateFrom(14, 2, 2026, 13, 00),
            endDate: Date().dateFrom(14, 2, 2026, 14, 00),
            text: "Saturday",
            backCol: "#3E56C2"
        ),
        CKEvent(
            startDate: Date().dateFrom(15, 2, 2026, 16, 30),
            endDate: Date().dateFrom(15, 2, 2026, 17),
            text: "Sunday",
            backCol: "#F6D264"
        )
    ]

    @State private var date = Date()

    @State private var mode: CKCalendarMode = .day
    @State private var showNewEventSheet = false

    @StateObject private var observer = CKCalendarObserver()

    private var day: some View {
        return CKTimelineDay(observer: observer, events: events, date: $date)
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
        CKMonth(observer: observer, events: events, date: $date)
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
        monthCompact
    }

    @ViewBuilder
    private func page() -> some View {

        Group {
            switch mode {
            case .day:
                if horizontalSizeClass == .compact {
                    dayCompact
                } else {
                    if !observer.eventSelected {
                        day
                    } else {
                        Text(observer.event.text)
                    }
                }

            case .week:
                if horizontalSizeClass == .compact {
                    weekCompact
                } else {
                    week
                }

            case .month:
                if horizontalSizeClass == .compact {
                    monthCompact
                } else {
                    month
                }
            }
        }
        .toolbar {
            ToolbarItemGroup {
                CKCalendarPicker(mode: $mode)
                Button {
                    showNewEventSheet = true
                } label: {
                    Label("Add", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showNewEventSheet) {
            EmptyView()
        }
    }
}

#Preview {
    ContentView()
}

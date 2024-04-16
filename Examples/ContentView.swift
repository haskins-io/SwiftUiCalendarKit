//
//  SwiftUIView.swift
//  
//
//  Created by Mark Haskins on 16/04/2024.
//

import SwiftUI

struct ContentView: View {

    @State private var date = Date()

    @StateObject private var observer = CKCalendarObserver()

    let event1 = CKEvent(
        startDate: Date().dateFrom(13, 4, 2024, 12, 00),
        endDate: Date().dateFrom(13, 4, 2024, 13, 00),
        text: "Event 1",
        backCol: "#D74D64"
    )

    let event2 = CKEvent(
        startDate: Date().dateFrom(13, 4, 2024, 12, 15),
        endDate: Date().dateFrom(13, 4, 2024, 13, 15),
        text: "Event 2",
        backCol: "#3E56C2"
    )

    let event3 = CKEvent(
        startDate: Date().dateFrom(13, 4, 2024, 12, 30),
        endDate: Date().dateFrom(13, 4, 2024, 15, 01),
        text: "Event 3",
        backCol: "#F6D264"
    )

    private var dayCompact: some View {
        return CKCompactDay(
            detail: { event in EventDetail(event: event) },
            events: [event1, event2, event3],
            date: $date
        )
    }

    private var month: some View {
        CKMonth(
            observer: observer,
            events: [event1, event2, event3],
            date: $date
        )
    }

    var body: some View {
        if horizontalSizeClass == .compact {
            NavigationView {
                dayCompact
            }.accentColor(.black)
        } else {
            month
        }
    }
}

#Preview {
    ContentView()
}

//
//  CalendarCompactMonth.swift
//  freya
//
//  Created by Mark Haskins on 09/04/2024.
//

import SwiftUI

public struct CKCompactMonth: View {

    @ObservedObject var observer: CKCalendarObserver

    @Binding private var date: Date

    private var events: [any CKEventSchema]

    public init(observer: CKCalendarObserver, events: [any CKEventSchema], date: Binding<Date>) {
        self._observer = .init(wrappedValue: observer)
        self.events = events
        self._date = date
    }

    public var body: some View {
        VStack {
            CKMonthComponent(calendar: Calendar(identifier: .gregorian), date: $date)
            Divider()
            List {
                Text("Event")
            }.listStyle(.plain)
        }
    }
}

#Preview {
    CKCompactMonth(
        observer: CKCalendarObserver(),
        events: [
            CKEvent(startDate: Date().dateFrom(13, 4, 2024, 12, 00), endDate: Date().dateFrom(13, 4, 2024, 13, 00), text: "Date 1"),
            CKEvent(startDate: Date().dateFrom(14, 4, 2024, 12, 30), endDate: Date().dateFrom(14, 4, 2024, 13, 30), text: "Date 2"),
            CKEvent(startDate: Date().dateFrom(15, 4, 2024, 15, 00), endDate: Date().dateFrom(15, 4, 2024, 16, 00), text: "Date 3"),
        ],
        date: .constant(Date().dateFrom(13, 4, 2024))
    )
}

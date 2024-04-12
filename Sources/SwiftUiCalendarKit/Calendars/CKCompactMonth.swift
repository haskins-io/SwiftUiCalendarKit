//
//  CalendarCompactMonth.swift
//  freya
//
//  Created by Mark Haskins on 09/04/2024.
//

import SwiftUI

public struct CKCompactMonth: View {

    @State private var date = Date()

    private var events: [any CKEventSchema]

    public init(events: [any CKEventSchema]) {
        self.events = events
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
    CKCompactMonth(events: [])
}

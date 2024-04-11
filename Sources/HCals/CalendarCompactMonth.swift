//
//  CalendarCompactMonth.swift
//  freya
//
//  Created by Mark Haskins on 09/04/2024.
//

import SwiftUI

struct CalendarCompactMonth: View {

    @State private var date = Date()

    var body: some View {
        VStack {
            CalendarViewComponent(calendar: Calendar(identifier: .gregorian), date: $date)
            Divider()
            List {
                Text("Event")
            }.listStyle(.plain)
        }
    }
}

#Preview {
    CalendarCompactMonth()
}

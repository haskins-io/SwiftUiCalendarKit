//
//  CalendarCompactMonth.swift
//  freya
//
//  Created by Mark Haskins on 09/04/2024.
//

import SwiftUI

struct CKCompactMonth: View {

    @State private var date = Date()

    var body: some View {
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
    CKCompactMonth()
}

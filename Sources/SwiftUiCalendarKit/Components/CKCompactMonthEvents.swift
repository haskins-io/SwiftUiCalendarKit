//
//  CKCompactMonthEvents.swift
//  
//
//  Created by Mark Haskins on 14/04/2024.
//

import SwiftUI

struct CKCompactMonthEvents<Detail: View>: View {

    @Binding private var date: Date

    private let calendar = Calendar.current

    private let detail: (CKEvent) -> Detail
    private var events: [CKEvent]

    init(
        events: [CKEvent],
        @ViewBuilder detail: @escaping (CKEvent) -> Detail,
        date: Binding<Date>
    ) {
        self.detail = detail
        self.events = events
        self._date = date
    }

    var body: some View {

        List {
            // Filtered before the `ForEach` rather than inside it: a `List` builds a row for
            // every element it is handed, so hiding most of them behind an `if` still pays for
            // them.
            ForEach(events.filter { CKUtils.doesEventOccurOnDate(event: $0, date: date) }) { event in
                NavigationLink(destination: detail(event)) {
                    CKListEventView(event: event)
                }
            }
        }
        .listStyle(.plain)
    }
}

#Preview {
    CKCompactMonthEvents(
        events: testEvents,
        detail: { _ in EmptyView() },
        date: .constant(Date())
    )
}

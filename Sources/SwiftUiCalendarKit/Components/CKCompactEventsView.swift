//
//  CKCompactEventsView.swift
//  SwiftUiCalendarKit
//
//  Created by Mark Haskins on 17/02/2026.
//

import SwiftUI

struct CKCompactEventsView<Detail: View>: View {

    var eventData: [CKEventViewData]
    var detail: (CKEvent) -> Detail

    var body: some View {
        ForEach(eventData) { event in
            CKCompactEventView(event, detail: detail)
        }
    }
}

#Preview {
    CKCompactEventsView(
        eventData: [],
        detail: { _ in EmptyView() }
    )
}

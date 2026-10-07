//
//  SwiftUIView.swift
//  SwiftUiCalendarKit
//
//  Created by Mark Haskins on 17/02/2026.
//

import SwiftUI

struct CKCompactDayEventsView<Detail: View>: View {

    var layout: CKLayout
    var detail: (CKEvent) -> Detail

    var body: some View {
        VStack(spacing: 0) {
            ForEach(layout.bands + layout.markers) { event in
                CKCompactDayEventView(event, detail: detail)
            }
        }
    }
}

#Preview {
    CKCompactDayEventsView(
        layout: CKLayout(bands: testEvents.filter { $0.kind.lane == .band }),
        detail: { _ in EmptyView() }
    )
}


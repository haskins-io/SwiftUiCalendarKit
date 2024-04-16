//
//  File.swift
//  
//
//  Created by Mark Haskins on 16/04/2024.
//

import SwiftUI
import SwiftUiCalendarKit

struct EventDetail: View {

    var event: any CKEventSchema

    var body: some View {
        Text(event.text)
    }
}

#Preview {
    EventDetail(
        event: CKEvent(
            startDate: Date().dateFrom(13, 4, 2024, 12, 15),
            endDate: Date().dateFrom(13, 4, 2024, 13, 15),
            text: "Fixed all the bugs",
            backCol: "#3E56C2"
        )
    )
}

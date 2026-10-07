//
//  SwiftUiCalendarKit.swift
//  
//
//  Created by Mark Haskins on 16/04/2024.
//

import SwiftUI
import SwiftUiCalendarKit

struct EventDetail: View {

    var event: any CKEvent

    var body: some View {
        Text(event.title)
    }
}

#Preview {
    EventDetail(
        event: CKEvent(
            kind: .timed(
                start:  Calendar.current.date(bySettingHour: 9, minute: 25, second: 0, of: Date()) ?? Date(),
                end: Calendar.current.date(bySettingHour: 9, minute: 00, second: 0, of: Date()) ?? Date()
            ),
            title: "Title",
            subtitle: "subtitle",
            systemImage: "star",
            tint: Color.secondary,
            isTentative: false
        )
    )
}

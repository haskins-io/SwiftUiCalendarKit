//
//  SwiftUIView.swift
//  
//
//  Created by Mark Haskins on 16/04/2024.
//

import SwiftUI

struct CKListEventView: View {

    var event: any CKEventSchema

    var body: some View {
        VStack(alignment: .leading) {
            Text(event.startDate.formatted(.dateTime.hour().minute()))
            Text(event.text).bold()
                .listRowBackground(event.backgroundAsColor())
        }
        .font(.caption)
    }
}

#Preview {
    CKListEventView(
        event: CKEvent(startDate: Date().dateFrom(14, 4, 2024, 12, 00), endDate: Date().dateFrom(14, 4, 2024, 13, 00), text: "Event 1")
    )
}

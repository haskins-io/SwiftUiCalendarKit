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
            HStack {
                Text(event.startDate.formatted(.dateTime.hour().minute())).padding(.leading, 5)
                Text("-")
                Text(event.endDate.formatted(.dateTime.hour().minute()))
            }
            .padding(.leading, 5)
            Text(event.text).bold().padding(.leading, 5).padding(.leading, 5)
        }
        .font(.caption)
        .overlay {
            HStack {
                Rectangle()
                    .fill(event.backgroundAsColor())
                    .frame(maxHeight: .infinity, alignment: .leading)
                    .frame(width: 4)
                Spacer()
            }
        }
    }
}

#Preview {
    CKListEventView(event:
        CKEvent(
            startDate: Date().dateFrom(13, 4, 2024, 1, 00),
            endDate: Date().dateFrom(13, 4, 2024, 2, 00),
            text: "Event 1",
            backCol: "#D74D64")
    )
}

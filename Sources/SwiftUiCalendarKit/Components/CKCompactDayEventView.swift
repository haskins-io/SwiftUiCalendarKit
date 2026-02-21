//
//  SwiftUIView.swift
//  SwiftUiCalendarKit
//
//  Created by Mark Haskins on 17/02/2026.
//

import SwiftUI

struct CKCompactDayEventView<Detail: View>: View {

    private let detail: (any CKEventSchema) -> Detail
    private let eventData: CKEventViewData
    private let event: any CKEventSchema

    init(_ eventData: CKEventViewData,
         @ViewBuilder detail: @escaping (any CKEventSchema) -> Detail
    ) {
        self.detail = detail
        self.eventData = eventData
        self.event = eventData.event
    }

    var body: some View {
        NavigationLink {
            detail(event)
        } label: {
            HStack {

                if !event.sfImage.isEmpty{
                    Image(systemName: event.sfImage)
                        .padding(.leading, 10)
                } else if !event.image.isEmpty {
                    Image(event.image)
                        .resizable()
                        .frame(width: 25, height: 20)
                        .padding(.leading, 10)
                }

                Text(CKUtils.eventText(event: event))
                    .padding(.leading, 5)
            }
            .font(.body)
            .foregroundColor(.primary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(6)
            .background(
                RoundedRectangle(cornerRadius: 3)
                    .fill(event.backgroundAsColor())
                    .opacity(0.5)
            )
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
}

#Preview {
    CKCompactDayEventView(
        CKEventViewData(
            event: CKEvent(
                startDate: Date().dateFrom(13, 4, 2024, 1, 00),
                endDate: Date().dateFrom(13, 4, 2024, 2, 00),
                isAllDay: true,
                primaryText: "Event 1",
                backCol: "#D74D64"),
            overlapsWith: 1,
            position: 1,
            width: 150
        ),
        detail: { _ in EmptyView() }
    )
}

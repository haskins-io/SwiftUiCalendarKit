//
//  CKCompactEventView.swift
//
//
//  Created by Mark Haskins on 15/04/2024.
//

import SwiftUI

struct CKCompactEventView<Detail: View>: View {

    @Environment(\.ckConfig)
    private var config

    private let detail: (any CKEventSchema) -> Detail

    private let eventData: CKEventViewData
    private let xOffset: CGFloat
    private let event: any CKEventSchema

    init(_ eventData: CKEventViewData,
         @ViewBuilder detail: @escaping (any CKEventSchema) -> Detail
    ) {
        self.detail = detail
        self.eventData = eventData
        self.event = eventData.event

        if eventData.position > 1 {
            xOffset = ((eventData.eventWidth + 10) * (eventData.position - 1)) + 40
        } else {
            xOffset = 40
        }
    }

    var body: some View {
        if Calendar.current.differenceInMinutes(start: event.startDate, end: event.endDate) >= 30 {
            greaterThan30mins()
        } else {
            lessThan30mins()
        }
    }

    @ViewBuilder
    private func greaterThan30mins() -> some View {
        VStack {
            NavigationLink {
                detail(event)
            } label: {
                VStack(alignment: .leading) {
                    Text(event.startDate.formatted(.dateTime.hour().minute())).padding(.leading, 5)

                    Text(event.text).bold().padding(.leading, 5)

                    if !event.primaryText.isEmpty {
                        Text(event.primaryText).font(.caption).foregroundColor(.secondary)
                    }

                    if !event.secondaryText.isEmpty {
                        Text(event.secondaryText).font(.caption).foregroundColor(.secondary)
                    }
                }
                .foregroundColor(.primary)
                .font(.caption)
                .frame(width: eventData.eventWidth, alignment: .leading)
                .padding(4)
                .frame(height: eventData.height, alignment: .top)
                .background(.thinMaterial)
                .background(
                    RoundedRectangle(cornerRadius: 5)
                        .fill(event.backgroundAsColor())
                        .opacity(0.5)
                        .shadow(radius: 5, x: 2, y: 5)
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
                .padding(.trailing, 30)
            }
        }
        .offset(x: xOffset, y: eventData.yOffset + 30)
    }

    @ViewBuilder
    private func lessThan30mins() -> some View {
        VStack {
            NavigationLink {
                detail(event)
            } label: {
                HStack(alignment: .center) {
                    Text(event.startDate.formatted(.dateTime.hour().minute())).padding(.leading, 5)
                    Text(event.text).bold()
                }
                .foregroundColor(.primary)
                .font(.caption)
                .frame(width: eventData.eventWidth, alignment: .leading)
                .padding(4)
                .frame(height: eventData.height, alignment: .top)
                .background(.thinMaterial)
                .background(
                    RoundedRectangle(cornerRadius: 5)
                        .fill(event.backgroundAsColor())
                        .opacity(0.5)
                        .shadow(radius: 5, x: 2, y: 5)
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
                .padding(.trailing, 30)
            }
        }
        .offset(x: xOffset, y: eventData.yOffset + 30)
    }
}

#Preview {
    CKCompactEventView(
        CKEventViewData(
            event: CKEvent(
                startDate: Date().dateFrom(13, 4, 2024, 1, 00),
                endDate: Date().dateFrom(13, 4, 2024, 2, 20),
                isAllDay: false,
                text: "Event 1 Event 1 Event 1",
                backCol: "#D74D64"),
            overlapsWith: 1,
            position: 1,
            width: 150
        ),
        detail: { _ in EmptyView() }
    )
}

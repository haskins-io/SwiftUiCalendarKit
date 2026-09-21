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

    private let detail: (CKEvent) -> Detail

    private let eventData: CKEventViewData
    private let xOffset: CGFloat
    private let event: CKEvent

    init(_ eventData: CKEventViewData,
         @ViewBuilder detail: @escaping (CKEvent) -> Detail
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

                    HStack {
                        if !event.systemImage.isEmpty {
                            Image(systemName: event.systemImage)
                                .padding(.leading, 5)
                        }

                        Text(event.title)
                            .bold()
                            .padding(.leading, 5)
                    }

                    if let subtitle = event.subtitle {
                        Text(subtitle)
                            .foregroundColor(.secondary)
                            .padding(.leading, 5)
                    }
                }
                .foregroundColor(.primary)
                .font(.caption)
                .frame(width: eventData.eventWidth, alignment: .leading)
                .padding(4)
                .frame(height: eventData.height, alignment: .top)
                .background(
                    RoundedRectangle(cornerRadius: 5)
                        .fill(event.tint)
                        .opacity(0.5)
                        .shadow(radius: 5, x: 2, y: 5)
                )
                .overlay {
                    HStack {
                        Rectangle()
                            .fill(event.tint)
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

                    HStack {
                        Text(event.startDate.formatted(.dateTime.hour().minute()))
                            .padding(.leading, 5)

                        if !event.systemImage.isEmpty {
                            Image(systemName: event.systemImage)
                        }

                        Text(event.title)
                            .bold()
                            .padding(.leading, 5)
                    }
                }
                .foregroundColor(.primary)
                .font(.caption)
                .frame(width: eventData.eventWidth, alignment: .leading)
                .padding(4)
                .frame(height: eventData.height, alignment: .top)
                .background(
                    RoundedRectangle(cornerRadius: 5)
                        .fill(event.tint)
                        .opacity(0.5)
                        .shadow(radius: 5, x: 2, y: 5)
                )
                .overlay {
                    HStack {
                        Rectangle()
                            .fill(event.tint)
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

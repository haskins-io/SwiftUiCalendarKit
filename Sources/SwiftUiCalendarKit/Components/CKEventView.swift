//
//  CKEventView.swift
//  
//
//  Created by Mark Haskins on 12/04/2024.
//

import SwiftUI

struct CKEventView: View {

    @Environment(\.ckConfig)
    private var config

    @State var observer: CKCalendarObserver

    private let eventData: CKEventViewData
    private let xOffset: CGFloat
    private let event: CKEvent

    /// A block on a single day's hour grid.
    init(_ eventData: CKEventViewData, observer: CKCalendarObserver) {
        self.eventData = eventData
        self._observer = .init(wrappedValue: observer)

        self.event = eventData.event
        self.xOffset = eventData.position > 1
        ? 47 + (eventData.eventWidth + 5) * (eventData.position - 1)
        : 47
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
        .frame(maxWidth: eventData.eventWidth - 5, alignment: .leading)
        .padding(4)
        .frame(height: eventData.height, alignment: .top)
        .background(.thinMaterial)
        .background(
            RoundedRectangle(cornerRadius: 3)
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
        .offset(x: xOffset, y: eventData.yOffset + 30)
        .onTapGesture {
            observer.event = event
        }
    }

    @ViewBuilder
    private func lessThan30mins() -> some View {
        HStack(alignment: .center) {
            Text(event.startDate.formatted(.dateTime.hour().minute())).padding(.leading, 5)

            if !event.systemImage.isEmpty {
                Image(systemName: event.systemImage)
                    .padding(.leading, 5)
            }

            Text(event.title)
                .bold()
                .padding(.leading, 5)
        }
        .foregroundColor(.primary)
        .font(.caption)
        .frame(maxWidth: eventData.eventWidth - 5, alignment: .leading)
        .padding(4)
        .frame(height: eventData.height, alignment: .top)
        .background(
            RoundedRectangle(cornerRadius: 3)
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
        .offset(x: xOffset, y: eventData.yOffset + 30)
        .onTapGesture {
            observer.event = event
        }
    }
}

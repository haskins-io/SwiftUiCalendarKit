//
//  CKDayEventView.swift
//
//  Created by Mark Haskins on 15/02/2026.
//

import SwiftUI

struct CKDayEventView: View {

    @State var observer: CKCalendarObserver

    private let event: CKEvent
    private let width: CGFloat

    /// A chip for the strip above the hour grid — a band or a marker, never a `.timed` event.
    ///
    /// Takes a `CKEvent` rather than a `CKEventViewData` because view data exists only for the
    /// grid lane: `CKEventViewData.init` refuses every kind but `.timed`, so an all-day event or
    /// a deadline has no geometry to hand this and never did.
    init(_ event: CKEvent, observer: CKCalendarObserver, width: CGFloat) {
        self.event = event
        self._observer = .init(wrappedValue: observer)
        self.width = width
    }

    var body: some View {
        HStack {
            if !event.systemImage.isEmpty {
                Image(systemName: event.systemImage)
                    .padding(.leading, 10)
            }

            Text(event.title)
                .padding(.leading, 5)
        }
        .foregroundColor(.primary)
        .font(.body)
        .frame(maxWidth: width, alignment: .leading)
        .padding(6)
        .background(
            RoundedRectangle(cornerRadius: 3)
                .fill(event.tint)
                .opacity(0.3)
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
        .onTapGesture {
            observer.event = event
        }
    }
}

//
//  SwiftUIView.swift
//  SwiftUiCalendarKit
//
//  Created by Mark Haskins on 17/02/2026.
//

import SwiftUI

struct CKCompactDayEventView<Detail: View>: View {

    private let detail: (CKEvent) -> Detail
    private let event: CKEvent

    init(_ event: CKEvent,
         @ViewBuilder detail: @escaping (CKEvent) -> Detail
    ) {
        self.detail = detail
        self.event = event
    }

    var body: some View {
        NavigationLink {
            detail(event)
        } label: {
            HStack {

                if !event.systemImage.isEmpty {
                    Image(systemName: event.systemImage)
                        .padding(.leading, 10)
                }

                Text(event.title)
                    .font(.subheadline)
                    .padding(.leading, 5)
            }
            .font(.body)
            .foregroundColor(.primary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(6)
            .background(
                RoundedRectangle(cornerRadius: 3)
                    .fill(event.tint)
                    .opacity(0.15)
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
        }
    }
}

//
//  CKListEventView.swift
//  
//
//  Created by Mark Haskins on 16/04/2024.
//

import SwiftUI

/// One row in the compact month's list of the selected day.
struct CKListEventView: View {

    var event: CKEvent

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {

            when
                .padding(.leading, 5)

            HStack(spacing: 5) {
                if !event.systemImage.isEmpty {
                    Image(systemName: event.systemImage)
                }

                Text(event.title)
                    .bold()
            }
            .padding(.leading, 5)

            if let subtitle = event.subtitle {
                Text(subtitle)
                    .foregroundStyle(.secondary)
                    .padding(.leading, 5)
            }
        }
        .font(.caption)
        .padding(.leading, 5)
        .overlay(alignment: .leading) {
            Rectangle()
                .fill(event.tint)
                .frame(width: 4)
        }
    }

    @ViewBuilder private var when: some View {
        switch event.kind {
        case .timed(let start, let end):
            Text("\(start.formatted(.dateTime.hour().minute())) – \(end.formatted(.dateTime.hour().minute()))")
                .foregroundStyle(.secondary)

        case .allDay:
            Text("All day")
                .foregroundStyle(.secondary)

        case .deadline(let at):
            Text("Due \(at.formatted(.dateTime.hour().minute()))")
                .foregroundStyle(.secondary)

        case .span(let from, let through):
            Text("\(from.formatted(.dateTime.day().month(.abbreviated)))"
                 + " – \(through.formatted(.dateTime.day().month(.abbreviated)))")
            .foregroundStyle(.secondary)
        }
    }
}

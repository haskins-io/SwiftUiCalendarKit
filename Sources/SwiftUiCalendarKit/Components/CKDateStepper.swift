//
//  File.swift
//  SwiftUiCalendarKit
//
//  Created by Mark Haskins on 21/09/2026.
//

import SwiftUI

/// The ‹ Today › cluster every calendar style uses to move through time.
struct CKDateStepper: View {

    @Environment(\.locale)
    private var locale

    @Binding var date: Date

    /// What one press moves by — `.day`, `.weekOfYear` or `.month`.
    let component: Calendar.Component

    var body: some View {
        HStack(spacing: 1) {

            Button {
                self.step(-1)
            } label: {
                Image(systemName: "chevron.backward.circle")
            }
            .accessibilityLabel(Text(CKStrings.previous(self.component).locale(self.locale)))

            Button {
                withAnimation {
                    self.date = Date.now
                }
            } label: {
                Image(systemName: "clock.circle")
            }

            Button {
                self.step(1)
            } label: {
                Image(systemName: "chevron.forward.circle")
            }
            .accessibilityLabel(Text(CKStrings.next(self.component).locale(self.locale)))
        }
        .font(.title)
    }

    private func step(_ value: Int) {
        withAnimation {
            self.date = Self.stepped(self.date, by: value, component: self.component)
        }
    }

    /// `date` moved by `value` units of `component`, or `date` itself if it cannot be moved.
    static func stepped(
        _ date: Date,
        by value: Int,
        component: Calendar.Component,
        calendar: Calendar = .current
    ) -> Date {
        calendar.date(byAdding: component, value: value, to: date) ?? date
    }
}

#Preview {
    CKDateStepper(date: .constant(Date()), component: .day)
}

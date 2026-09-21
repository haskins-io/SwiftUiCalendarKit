//
//  File.swift
//  SwiftUiCalendarKit
//
//  Created by Mark Haskins on 21/09/2026.
//

import SwiftUI

/// The ‹ Today › cluster every calendar style uses to move through time.
struct CKDateStepper: View {

    @Binding var date: Date

    /// What one press moves by — `.day`, `.weekOfYear` or `.month`.
    let component: Calendar.Component

    var body: some View {
        HStack(spacing: 1) {

            Button {
                self.step(-1)
            } label: {
                Image(systemName: "chevron.left.circle")
            }
            .accessibilityLabel(Self.previousLabel(for: self.component))

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
                Image(systemName: "chevron.right.circle")
            }
            .accessibilityLabel(Self.nextLabel(for: self.component))
        }
        .font(.title)
    }

    private func step(_ value: Int) {
        withAnimation {
            guard let moved = Calendar.current.date(
                byAdding: self.component, value: value, to: self.date
            ) else {
                return
            }

            self.date = moved
        }
    }

    private static func previousLabel(for component: Calendar.Component) -> String {
        switch component {
        case .day:
            "Previous day"

        case .weekOfYear:
            "Previous week"

        default:
            "Previous month"
        }
    }

    private static func nextLabel(for component: Calendar.Component) -> String {
        switch component {
        case .day:
            "Next day"

        case .weekOfYear:
            "Next week"

        default:
            "Next month"
        }
    }
}

#Preview {
    CKDateStepper(date: .constant(Date()), component: .day)
}

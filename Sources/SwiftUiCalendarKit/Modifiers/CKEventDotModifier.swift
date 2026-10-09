//
//  CKEventDotModifier.swift
//  SwiftUiCalendarKit
//
//  Created by Mark Haskins on 09/10/2026.
//

import SwiftUI

/// The dot under a compact month's day number that says the day has events.
///
/// Hung off the bottom centre of the number, so it stays under it whatever the column width or
/// layout direction. It used to be a 5×5 circle drawn in the corner of a cell-wide shape and
/// pushed 23 points in from the leading edge, which only looked centred when a column happened to
/// be about 50 points wide, and sat off to one side in a right-to-left layout.
struct CKEventDotModifier: ViewModifier {

    /// Whether to show the dot.
    let isVisible: Bool

    static let diameter: CGFloat = 5

    /// The gap between the bottom of the number and the top of the dot.
    static let gap: CGFloat = 2

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .bottom) {
                if self.isVisible {
                    Circle()
                        .fill(.green)
                        .frame(width: Self.diameter, height: Self.diameter)
                        // From resting on the content's bottom edge to `gap` below it. Only a
                        // horizontal offset is affected by layout direction, so this one is safe.
                        // (An `alignmentGuide` would read better, but the overlay ignores it.)
                        .offset(y: Self.diameter + Self.gap)
                }
            }
    }
}

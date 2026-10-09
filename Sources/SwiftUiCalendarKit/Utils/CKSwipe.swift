//
//  CKSwipe.swift
//  SwiftUiCalendarKit
//
//  Created by Mark Haskins on 09/10/2026.
//

import SwiftUI

/// Which way a horizontal swipe moves through the calendar.
///
/// Swiping towards the leading edge moves forward in time, as turning a page does: leftwards in
/// a left-to-right language and rightwards in a right-to-left one. A drag's translation does
/// not mirror with the layout (x still grows to the right in a right-to-left layout), so the
/// direction has to be taken into account here.
nonisolated enum CKSwipe {

    /// The step a finished drag moves by: `1` forward, `-1` back, or `nil` when the drag was
    /// mostly vertical (that belongs to the hour grid's scroll view) or did not move sideways.
    static func step(translation: CGSize, layoutDirection: LayoutDirection) -> Int? {
        guard translation.width != 0, abs(translation.width) > abs(translation.height) else {
            return nil
        }

        let towardsLeft = translation.width < 0

        return switch layoutDirection {
        case .rightToLeft:
            towardsLeft ? -1 : 1

        case .leftToRight:
            towardsLeft ? 1 : -1

        @unknown default:
            towardsLeft ? 1 : -1
        }
    }
}

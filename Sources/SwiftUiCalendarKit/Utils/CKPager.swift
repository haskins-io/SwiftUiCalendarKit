//
//  CKPager.swift
//  SwiftUiCalendarKit
//
//  Created by Mark Haskins on 07/10/2026.
//

import Foundation

/// The sliding window of pages behind the swipeable day and week strips.
///
/// The strips hold three pages — the previous, the current and the next — and when a swipe
/// lands on either end, a new page is added beyond it and one dropped from the far side, so there
/// is always somewhere to swipe to. Shared by `CKCompactDay` (pages of days) and `CKCompactWeek`
/// (pages of weeks).
nonisolated enum CKPager {

    /// The initial window: the page before `centre`, `centre`, and the page after.
    static func window<Page>(
        around centre: Page,
        previous: (Page) -> Page?,
        next: (Page) -> Page?
    ) -> [Page] {

        var pages: [Page] = []

        if let before = previous(centre) {
            pages.append(before)
        }

        pages.append(centre)

        if let after = next(centre) {
            pages.append(after)
        }

        return pages
    }

    /// Slides the window when `index` is on either end of it, so the selected page is no longer
    /// at an edge. The window keeps its size.
    ///
    /// - Returns: the new pages, and the index the selected page now sits at. Unchanged when
    ///   `index` is not at an end, or is out of range.
    static func recentre<Page>(
        _ pages: [Page],
        at index: Int,
        previous: (Page) -> Page?,
        next: (Page) -> Page?
    ) -> (pages: [Page], index: Int) {

        guard pages.count > 1, pages.indices.contains(index) else {
            return (pages, index)
        }

        var pages = pages

        if index == 0, let first = pages.first, let before = previous(first) {
            pages.insert(before, at: 0)
            pages.removeLast()

            return (pages, 1)
        }

        if index == pages.count - 1, let last = pages.last, let after = next(last) {
            pages.append(after)
            pages.removeFirst()

            return (pages, pages.count - 2)
        }

        return (pages, index)
    }
}

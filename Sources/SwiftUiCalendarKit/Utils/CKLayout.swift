//
//  File.swift
//  SwiftUiCalendarKit
//
//  Created by Mark Haskins on 21/09/2026.
//

import Foundation

/// Everything a timeline needs to draw, for one visible range.
///
/// The three lanes arrive together because they are computed together, and because a view that
/// holds only the grid ends up asking the other two questions in `body` — which is how the
/// all-day rows came to be filtered out of grid data in the first place.
nonisolated struct CKLayout: Sendable {

    /// `.timed` events with their column geometry — the hour grid.
    var grid: [CKEventViewData] = []

    /// All-day and multi-day events, for the band row above the grid.
    var bands: [CKEvent] = []

    /// Deadlines, for the marker row.
    var markers: [CKEvent] = []

    /// Bands that cross a day boundary, and so want one bar across several columns.
    func multiDayBands(in calendar: Calendar) -> [CKEvent] {
        self.bands.filter { $0.isMultiDay(in: calendar) }
    }

    /// Bands confined to a single day, which sit in the all-day row beside the markers.
    func singleDayBands(in calendar: Calendar) -> [CKEvent] {
        self.bands.filter { !$0.isMultiDay(in: calendar) }
    }
}

/// Builds a `CKLayout` off the main actor.
nonisolated enum CKLayoutBuilder {

    /// The layout for the week containing `date`.
    ///
    /// `width` is the column width. A non-positive width means the view has not been measured
    /// yet, and laying out against it produces negative event widths, so it yields nothing
    /// rather than a pass that has to be thrown away.
    @concurrent
    static func week(date: Date, events: [CKEvent], width: CGFloat) async -> CKLayout {

        guard width > 0 else {
            return CKLayout()
        }

        let weekRange = date.fetchWeekRange()
        let interval = DateInterval(start: weekRange.lowerBound, end: weekRange.upperBound)

        return CKLayout(
            grid: CKUtils.generateEventViewData(date: date, events: events, width: width),
            bands: CKUtils.bandEvents(in: interval, events: events),
            markers: CKUtils.markerEvents(in: interval, events: events)
        )
    }

    /// The layout for a single day.
    @concurrent
    static func day(date: Date, events: [CKEvent], width: CGFloat) async -> CKLayout {

        guard width > 0 else {
            return CKLayout()
        }

        let interval = date.dayInterval

        return CKLayout(
            grid: CKUtils.generateEventViewData(date: date, events: events, width: width)
                .filter { Calendar.current.isDate($0.start, inSameDayAs: date) },
            bands: CKUtils.bandEvents(in: interval, events: events),
            markers: CKUtils.markerEvents(in: interval, events: events)
        )
    }

    /// One layout per day, for a pager that keeps its neighbours ready.
    @concurrent
    static func days(_ dates: [Date], events: [CKEvent], width: CGFloat) async -> [Date: CKLayout] {

        var layouts: [Date: CKLayout] = [:]

        for date in dates {
            layouts[date.midnight] = await Self.day(date: date, events: events, width: width)
        }

        return layouts
    }
}

/// What a layout depends on, so `.task(id:)` recomputes when any of it changes and not otherwise.
nonisolated struct CKLayoutRequest: Equatable, Sendable {
    let dates: [Date]
    let events: [CKEvent]
    let width: CGFloat
}

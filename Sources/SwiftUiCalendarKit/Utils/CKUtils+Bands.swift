//
//  File.swift
//  SwiftUiCalendarKit
//
//  Created by Mark Haskins on 21/09/2026.
//

import Foundation

/// How a week row's multi-day bands are laid out: which lane each one takes, how wide its bars
/// are, and how much space each individual day has to hold clear for them.
///
/// Split from `CKUtils` because it is a self-contained piece of geometry with its own vocabulary
/// — lanes decide heights, runs decide widths, reservations decide where a cell's own content can
/// start — and because `CKUtils` had grown past the file-length rule carrying it.
extension CKUtils {

    /// Assigns each multi-day band a lane that is the same in every cell it crosses, one week
    /// row at a time.
    ///
    /// This is what makes a band read as **one bar** across a month grid rather than a run of
    /// disconnected chips. Sorting the events per cell cannot do it: a band that is second in
    /// Tuesday's list and first in Wednesday's draws at two different heights, and the eye reads
    /// two things rather than one. The lane has to be decided for the row, not the day.
    ///
    /// Lanes are recomputed per week because that is the unit the grid draws — a band crossing a
    /// row boundary is free to change lane on the next row, which is what keeps the packing
    /// tight rather than inheriting a gap from a week the reader can no longer see.
    ///
    /// The returned column for a day is positional: `nil` means *this lane is empty here, leave
    /// the space*, and that hole is exactly what keeps the bars below it aligned. Trailing
    /// `nil`s are trimmed, because space after the last band is space the day's own events can
    /// have.
    static func bandLanes(
        days: [Date],
        events: [CKEvent],
        calendar: Calendar = .current
    ) -> [Date: [CKEvent?]] {

        let bands = events.filter { $0.kind.lane == .band && $0.isMultiDay(in: calendar) }

        guard !bands.isEmpty else {
            return [:]
        }

        var result: [Date: [CKEvent?]] = [:]

        for start in stride(from: 0, to: days.count, by: 7) {
            let week = Array(days[start..<min(start + 7, days.count)])

            guard let first = week.first, let last = week.last else {
                continue
            }

            let interval = DateInterval(start: first.midnight, end: last.endOfDay)

            // Longest first among events that start together, so the bar most likely to span the
            // whole row takes the top lane and the shorter ones stack under it.
            let crossing = bands
                .filter { $0.intersects(interval) }
                .sorted {
                    $0.startDate == $1.startDate
                    ? $0.endDate > $1.endDate
                    : $0.startDate < $1.startDate
                }

            var lanes: [[Date: CKEvent]] = []

            for band in crossing {
                let covered = week.filter { Self.doesEventOccurOnDate(event: band, date: $0) }

                guard !covered.isEmpty else {
                    continue
                }

                let free = lanes.firstIndex { lane in
                    covered.allSatisfy { lane[$0.midnight] == nil }
                }

                if let free {
                    for day in covered {
                        lanes[free][day.midnight] = band
                    }
                } else {
                    var lane: [Date: CKEvent] = [:]

                    for day in covered {
                        lane[day.midnight] = band
                    }

                    lanes.append(lane)
                }
            }

            for day in week {
                var column: [CKEvent?] = lanes.map { $0[day.midnight] }

                while let last = column.last, last == nil {
                    column.removeLast()
                }

                result[day.midnight] = column
            }
        }

        return result
    }

    /// The bands of one week row as unbroken runs, ready to be drawn as single views.
    ///
    /// Built on `bandLanes`, which decides the heights; this decides the widths. A run ends where
    /// the lane's occupant changes or the week does, so a band spanning Monday to Sunday is one
    /// run of seven and not seven runs of one — which is the difference between a title with a
    /// week to sit in and a title clipped to Monday.
    static func bandRuns(
        week: [Date],
        events: [CKEvent],
        calendar: Calendar = .current
    ) -> [CKBandRun] {

        let lanes = Self.bandLanes(days: week, events: events, calendar: calendar)

        guard !lanes.isEmpty else {
            return []
        }

        let laneCount = week.compactMap { lanes[$0.midnight]?.count }.max() ?? 0

        var runs: [CKBandRun] = []

        for lane in 0..<laneCount {

            var index = 0

            while index < week.count {

                guard let event = Self.band(in: lanes, day: week[index], lane: lane) else {
                    index += 1
                    continue
                }

                var length = 1

                while index + length < week.count,
                      let next = Self.band(in: lanes, day: week[index + length], lane: lane),
                      next.id == event.id {
                    length += 1
                }

                runs.append(CKBandRun(event: event, lane: lane, startIndex: index, length: length))

                index += length
            }
        }

        return runs
    }

    /// How many band rows each column of a week row actually needs.
    ///
    /// The row's deepest lane is **not** the answer for every day in it. Reserving the row's
    /// maximum in all seven cells is what pushed Tuesday's three chips down past two blank band
    /// rows because a trip ran across Saturday and Sunday — the space was held clear for bars
    /// that were never going to be drawn there.
    ///
    /// A day still reserves for the lanes *below* an occupied one, holes included: a band at
    /// lane 1 needs lane 0 kept clear beneath it on its own days, or the bars stop lining up,
    /// which is the whole point of assigning lanes for the row. So the count is the deepest lane
    /// reaching **this column**, plus one — not the deepest in the row, and not the number of
    /// bands the day carries.
    ///
    /// Pass the runs the row is actually going to draw. Runs beyond the row's cap are hidden and
    /// must not have space held for them.
    static func bandRowCounts(runs: [CKBandRun], columns: Int) -> [Int] {

        guard columns > 0 else {
            return []
        }

        var counts = Array(repeating: 0, count: columns)

        for run in runs {

            let last = min(run.startIndex + run.length, columns)

            guard run.startIndex < last else {
                continue
            }

            for index in run.startIndex..<last {
                counts[index] = max(counts[index], run.lane + 1)
            }
        }

        return counts
    }

    /// How many of `runs` cover each column of a week row.
    ///
    /// Sibling of ``bandRowCounts(runs:columns:)`` and deliberately not the same number: that one
    /// answers *how much space to hold clear*, which includes the empty lanes beneath an occupied
    /// one; this one answers *how many bands are actually there*, which is what "+ N more" is
    /// counting. Feed it the runs the row decided not to draw.
    static func bandCounts(runs: [CKBandRun], columns: Int) -> [Int] {

        guard columns > 0 else {
            return []
        }

        var counts = Array(repeating: 0, count: columns)

        for run in runs {

            let last = min(run.startIndex + run.length, columns)

            guard run.startIndex < last else {
                continue
            }

            for index in run.startIndex..<last {
                counts[index] += 1
            }
        }

        return counts
    }

    private static func band(in lanes: [Date: [CKEvent?]], day: Date, lane: Int) -> CKEvent? {

        guard let column = lanes[day.midnight], lane < column.count else {
            return nil
        }

        return column[lane]
    }
}


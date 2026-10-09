//
//  CKFormat.swift
//  SwiftUiCalendarKit
//
//  Created by Mark Haskins on 09/10/2026.
//

import Foundation

/// Dates and times as the views print them, in whatever form the locale writes them.
///
/// Gluing two formatted dates together with a dash fixes the separator, its spacing and the
/// order of the parts, all of which vary by locale. Interval format styles get them right and
/// drop whatever the two ends share ("9:00 – 10:30 AM", "14–16 Oct", "10月14日～16日"). Likewise,
/// a zero-padded hour assumes a 24-hour clock in Western digits.
///
/// Every function takes the locale and calendar so tests can pin them. The views use the
/// defaults, which follow the device's settings. The calendar's time zone is used throughout.
nonisolated enum CKFormat {

    /// A timed event's start and end, e.g. "09:00–10:30" or "9:00–10:30 AM".
    ///
    /// An end before the start is clamped to the start, so a malformed event reads as one time
    /// rather than trapping on an inverted range.
    static func timeRange(
        from start: Date,
        to end: Date,
        locale: Locale = .autoupdatingCurrent,
        calendar: Calendar = .autoupdatingCurrent
    ) -> String {
        let style = Date.IntervalFormatStyle(locale: locale, calendar: calendar, timeZone: calendar.timeZone)
            .hour()
            .minute()

        return (start..<max(start, end)).formatted(style)
    }

    /// The first and last day of a multi-day event, e.g. "14–16 Oct" or "14 Oct – 2 Nov".
    ///
    /// As with `timeRange`, a last day before the first is clamped to the first.
    static func dayRange(
        from first: Date,
        through last: Date,
        locale: Locale = .autoupdatingCurrent,
        calendar: Calendar = .autoupdatingCurrent
    ) -> String {
        let style = Date.IntervalFormatStyle(locale: locale, calendar: calendar, timeZone: calendar.timeZone)
            .day()
            .month(.abbreviated)

        return (first..<max(first, last)).formatted(style)
    }

    /// The label for `hour` (0–23) down the side of the hour grid.
    ///
    /// On a 24-hour clock it reads "09:00", as the grid always has. On a 12-hour clock the
    /// minutes are dropped, so the label reads "9 AM" rather than "9:00 AM" and fits the column.
    /// The digits and the AM/PM marker follow the locale.
    static func hourLabel(_ hour: Int, locale: Locale = .autoupdatingCurrent) -> String {
        // Formatted as a time on a fixed day in GMT rather than "today" in the reader's zone,
        // so a daylight-saving changeover can never skip or repeat an hour on the grid.
        let gmt = TimeZone.gmt
        let date = Date(timeIntervalSinceReferenceDate: TimeInterval(hour) * 3600)
        let style = Date.FormatStyle(locale: locale, timeZone: gmt)

        return switch locale.hourCycle {
        case .oneToTwelve, .zeroToEleven:
            date.formatted(style.hour())

        case .zeroToTwentyThree, .oneToTwentyFour:
            date.formatted(style.hour().minute())

        @unknown default:
            date.formatted(style.hour().minute())
        }
    }

    /// The names for `date`'s weekday from longest to shortest (abbreviated, short and narrow),
    /// with repeats removed.
    ///
    /// A day header shows the first that fits its column. Cutting a name to three characters
    /// works for English but breaks others: Hebrew "יום ד׳" becomes "יום" ("day").
    static func weekdaySymbols(
        _ date: Date,
        locale: Locale = .autoupdatingCurrent,
        calendar: Calendar = .autoupdatingCurrent
    ) -> [String] {
        let style = Date.FormatStyle(locale: locale, calendar: calendar, timeZone: calendar.timeZone)

        var symbols: [String] = []

        for width in [Date.FormatStyle.Symbol.Weekday.abbreviated, .short, .narrow] {
            let symbol = date.formatted(style.weekday(width))

            if !symbols.contains(symbol) {
                symbols.append(symbol)
            }
        }

        return symbols
    }
}

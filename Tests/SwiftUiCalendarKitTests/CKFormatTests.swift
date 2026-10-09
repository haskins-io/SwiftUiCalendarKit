// CKFormatTests.swift
//
// Dates and times as the views print them — `CKFormat`. Locales are pinned so the expectations
// do not depend on the machine running the tests.

@testable import SwiftUiCalendarKit
import Foundation
import Testing

@Suite("Formatting — ranges, hours and weekdays the way each locale writes them")
struct CKFormatTests {

    private static let britain = Locale(identifier: "en_GB")
    private static let america = Locale(identifier: "en_US")
    private static let arabic = Locale(identifier: "ar_EG")
    private static let hebrew = Locale(identifier: "he_IL")

    /// The formatters space ranges with thin and narrow no-break spaces, and which they use
    /// varies between OS releases, so the expectations below compare them as plain spaces.
    private static func plain(_ text: String) -> String {
        String(text.map { ["\u{2009}", "\u{202F}", "\u{00A0}"].contains($0) ? " " : $0 })
    }

    // MARK: Time ranges

    @Test("A time range uses the locale's clock and separator")
    func timeRange() {
        let range = { (locale: Locale) in
            Self.plain(CKFormat.timeRange(
                from: Fixture.at(9),
                to: Fixture.at(10, 30),
                locale: locale,
                calendar: Fixture.calendar
            ))
        }

        #expect(range(Self.britain) == "09:00 – 10:30")
        #expect(range(Self.america) == "9:00 – 10:30 AM")
    }

    @Test("A range that crosses noon keeps both markers on a 12-hour clock")
    func timeRangeAcrossNoon() {
        let range = CKFormat.timeRange(
            from: Fixture.at(9),
            to: Fixture.at(14),
            locale: Self.america,
            calendar: Fixture.calendar
        )

        #expect(Self.plain(range) == "9:00 AM – 2:00 PM")
    }

    @Test("An event that ends as it starts reads as one time, and one that ends early does not trap")
    func degenerateTimeRanges() {
        let zero = CKFormat.timeRange(
            from: Fixture.at(9),
            to: Fixture.at(9),
            locale: Self.britain,
            calendar: Fixture.calendar
        )
        let inverted = CKFormat.timeRange(
            from: Fixture.at(9),
            to: Fixture.at(8),
            locale: Self.britain,
            calendar: Fixture.calendar
        )

        #expect(zero == "09:00")
        #expect(inverted == "09:00")
    }

    @Test("Times are written in the locale's digits")
    func timeRangeDigits() {
        let range = CKFormat.timeRange(
            from: Fixture.at(9),
            to: Fixture.at(10, 30),
            locale: Self.arabic,
            calendar: Fixture.calendar
        )

        #expect(range.contains("٩"))
        #expect(!range.contains("9"))
    }

    // MARK: Day ranges

    @Test("A day range within one month names the month once")
    func dayRangeSameMonth() {
        let range = { (locale: Locale) in
            Self.plain(CKFormat.dayRange(
                from: Fixture.day(),
                through: Fixture.day(2).endOfDay,
                locale: locale,
                calendar: Fixture.calendar
            ))
        }

        #expect(range(Self.britain) == "14 – 16 Oct")
        #expect(range(Self.america) == "Oct 14 – 16")
    }

    @Test("A day range across months names both")
    func dayRangeAcrossMonths() {
        let range = CKFormat.dayRange(
            from: Fixture.day(),
            through: Fixture.day(19),
            locale: Self.britain,
            calendar: Fixture.calendar
        )

        #expect(Self.plain(range) == "14 Oct – 2 Nov")
    }

    @Test("A one-day range reads as that day, and a backwards one does not trap")
    func degenerateDayRanges() {
        let oneDay = CKFormat.dayRange(
            from: Fixture.day(),
            through: Fixture.day().endOfDay,
            locale: Self.britain,
            calendar: Fixture.calendar
        )
        let inverted = CKFormat.dayRange(
            from: Fixture.day(),
            through: Fixture.day(-3),
            locale: Self.britain,
            calendar: Fixture.calendar
        )

        #expect(oneDay == "14 Oct")
        #expect(inverted == "14 Oct")
    }

    // MARK: Hour labels

    @Test("On a 24-hour clock the grid reads as it always has", arguments: [
        (0, "00:00"),
        (9, "09:00"),
        (12, "12:00"),
        (23, "23:00")
    ])
    func hourLabels24(hour: Int, expected: String) {
        #expect(CKFormat.hourLabel(hour, locale: Self.britain) == expected)
    }

    @Test("On a 12-hour clock the grid drops the minutes and adds the marker", arguments: [
        (0, "12 AM"),
        (9, "9 AM"),
        (12, "12 PM"),
        (15, "3 PM")
    ])
    func hourLabels12(hour: Int, expected: String) {
        #expect(Self.plain(CKFormat.hourLabel(hour, locale: Self.america)) == expected)
    }

    @Test("Every hour of the day gets its own label", arguments: ["en_GB", "en_US", "ar_EG", "he_IL", "ja_JP"])
    func hourLabelsDistinct(identifier: String) {
        let labels = (0..<24).map { CKFormat.hourLabel($0, locale: Locale(identifier: identifier)) }

        #expect(Set(labels).count == 24)
    }

    @Test("Hour labels use the locale's digits")
    func hourLabelDigits() {
        let label = CKFormat.hourLabel(9, locale: Self.arabic)

        #expect(label.contains("٩"))
        #expect(!label.contains("9"))
    }

    // MARK: Weekdays

    @Test("Weekday names run from longest to shortest")
    func weekdaySymbolsEnglish() {
        let symbols = CKFormat.weekdaySymbols(Fixture.day(), locale: Self.britain, calendar: Fixture.calendar)

        #expect(symbols == ["Wed", "We", "W"])
    }

    @Test("Names are whole words from the locale, never cut short", arguments: [
        "en_GB", "fr_FR", "de_DE", "ar_EG", "he_IL", "ja_JP"
    ])
    func weekdaySymbolsAreWhole(identifier: String) {
        let locale = Locale(identifier: identifier)
        let symbols = CKFormat.weekdaySymbols(Fixture.day(), locale: locale, calendar: Fixture.calendar)
        let style = Date.FormatStyle(locale: locale, calendar: Fixture.calendar, timeZone: Fixture.calendar.timeZone)
        let names: [Date.FormatStyle.Symbol.Weekday] = [.abbreviated, .short, .narrow]

        #expect(!symbols.isEmpty)
        #expect(symbols.allSatisfy { symbol in
            names.contains { Fixture.day().formatted(style.weekday($0)) == symbol }
        })
    }

    @Test("Names that repeat are offered once")
    func weekdaySymbolsDeduplicated() {
        // Arabic's abbreviated and short names are both the full word.
        let arabic = CKFormat.weekdaySymbols(Fixture.day(), locale: Self.arabic, calendar: Fixture.calendar)

        #expect(arabic.count == Set(arabic).count)
        #expect(arabic.count < 3)
    }

    @Test("Hebrew keeps the day's letter rather than the word for \"day\"")
    func weekdaySymbolsHebrew() {
        let symbols = CKFormat.weekdaySymbols(Fixture.day(), locale: Self.hebrew, calendar: Fixture.calendar)

        #expect(symbols.allSatisfy { $0.contains("ד") })
    }

    @Test("Each day of the week gets its own name")
    func weekdaySymbolsPerDay() {
        let names = Fixture.week.map {
            CKFormat.weekdaySymbols($0, locale: Self.britain, calendar: Fixture.calendar).first
        }

        #expect(Set(names).count == 7)
    }
}

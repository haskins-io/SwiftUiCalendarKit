// MonthGridDayTests.swift

@testable import SwiftUiCalendarKit
import Foundation
import Testing

@Suite("Month grid — whole weeks, and no more of them than the month needs")
struct MonthGridDayTests {

    /// Fixed rather than `.current`: the row count is decided by where the 1st falls relative to
    /// the first weekday, so a test reading the machine's locale is asking about a different
    /// month shape on a Sunday-first one.
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.firstWeekday = 2
        calendar.timeZone = TimeZone(identifier: "Europe/London") ?? .gmt

        return calendar
    }

    private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day)) ?? Date()
    }

    @Test("A month ending on the last day of a week is five rows, not six")
    func fiveWeekMonth() {
        // Tue 1 Sep to Wed 30 Sep 2026: the grid runs Mon 31 Aug to Sun 4 Oct.
        let days = calendar.monthGridDays(for: date(2026, 9, 15))

        #expect(days.count == 35)
        #expect(days.first == date(2026, 8, 31))
        #expect(days.last == date(2026, 10, 4))
    }

    @Test("A month that spills into a sixth week still gets one")
    func sixWeekMonth() {
        // Sat 1 Aug to Mon 31 Aug 2026: the last day lands in a week of its own.
        let days = calendar.monthGridDays(for: date(2026, 8, 15))

        #expect(days.count == 42)
        #expect(days.first == date(2026, 7, 27))
        #expect(days.last == date(2026, 9, 6))
    }

    @Test("A February starting on the first weekday is four rows and no bleed")
    func fourWeekMonth() {
        // Mon 1 Feb to Sun 28 Feb 2027 — the only shape with no adjacent-month days at all.
        let days = calendar.monthGridDays(for: date(2027, 2, 15))

        #expect(days.count == 28)
        #expect(days.first == date(2027, 2, 1))
        #expect(days.last == date(2027, 2, 28))
    }

    @Test("Every day is one calendar day after the one before it")
    func daysAreContiguous() {
        // The grid indexes this array by row and column, so a gap or a repeat puts every
        // remaining date under the wrong weekday rather than failing outright. Across a whole
        // year so the clock changes are included.
        for month in 1...12 {
            let days = calendar.monthGridDays(for: date(2027, month, 15))

            #expect(days.count.isMultiple(of: 7), "month \(month) is not whole weeks")

            for index in days.indices.dropFirst() {
                let expected = calendar.date(byAdding: .day, value: 1, to: days[index - 1])

                #expect(days[index] == expected, "month \(month), day \(index)")
            }
        }
    }

    @Test("The grid starts on the reader's first weekday, whichever that is")
    func respectsFirstWeekday() throws {
        var sundayFirst = calendar
        sundayFirst.firstWeekday = 1

        let first = try #require(sundayFirst.monthGridDays(for: date(2026, 9, 15)).first)

        #expect(sundayFirst.component(.weekday, from: first) == 1)
        #expect(first == date(2026, 8, 30))
    }

    @Test("An interval shorter than the cap is not padded out to it")
    func generatedDaysStopAtTheEnd() {
        // The defect at the level it actually lived: the count was doing the deciding.
        let days = calendar.generateDays(
            for: DateInterval(start: date(2026, 9, 1), end: date(2026, 9, 8))
        )

        #expect(days.count == 7)
        #expect(days.last == date(2026, 9, 7))
    }
}

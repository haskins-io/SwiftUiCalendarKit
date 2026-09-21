// CKBandLaneTests.swift
//
// Lane assignment for multi-day bands in the month grid — `CKUtils.bandLanes`.

@testable import SwiftUiCalendarKit
import Foundation
import SwiftUI
import Testing

@Suite("Band lanes — one bar, one height, across a week")
struct CKBandLaneTests {

    private let calendar = Calendar.current

    private func day(_ offset: Int) -> Date {
        self.calendar.date(byAdding: .day, value: offset, to: Date().midnight) ?? Date()
    }

    /// A fortnight starting on the reader's first weekday, so the two rows are real week rows.
    private var days: [Date] {
        let today = Date().midnight
        let weekday = self.calendar.component(.weekday, from: today)
        let toStart = -((weekday - self.calendar.firstWeekday + 7) % 7)
        let start = self.calendar.date(byAdding: .day, value: toStart, to: today) ?? today

        return (0..<14).compactMap { self.calendar.date(byAdding: .day, value: $0, to: start) }
    }

    private func band(_ title: String, from: Date, through: Date, tint: Color = .green) -> CKEvent {
        CKEvent(
            id: CKEventID(recordID: UUID(), facet: .trip),
            kind: .span(from: from, through: through),
            title: title,
            tint: tint,
            source: .trip(UUID())
        )
    }

    private func timed(_ title: String, on date: Date) -> CKEvent {
        let start = self.calendar.date(bySettingHour: 10, minute: 0, second: 0, of: date) ?? date

        return CKEvent(
            id: CKEventID(recordID: UUID(), facet: .shoot),
            kind: .timed(start: start, end: start.addingTimeInterval(3_600)),
            title: title,
            tint: .blue,
            source: .booking(UUID())
        )
    }

    // MARK: - One band

    @Test("A band keeps the same lane in every cell it crosses")
    func aBandHoldsItsLane() throws {
        let days = self.days
        let week = Array(days.prefix(7))
        let band = self.band("Permit", from: week[0], through: week[6])

        let lanes = CKUtils.bandLanes(days: days, events: [band], calendar: self.calendar)

        for date in week {
            let column = try #require(lanes[date.midnight])

            #expect(column.count == 1)
            #expect(column[0]?.id == band.id)
        }
    }

    @Test("A day's own events never take a lane")
    func onlyBandsAreLaned() {
        let days = self.days
        let events = [self.timed("Shoot", on: days[2]), self.band("Permit", from: days[0], through: days[6])]

        let lanes = CKUtils.bandLanes(days: days, events: events, calendar: self.calendar)

        // A timed event belongs to its day and is drawn under the bars; laning it would reserve
        // space for it in six cells it has nothing to do with.
        #expect(lanes.values.allSatisfy { $0.compactMap { $0 }.allSatisfy { $0.title == "Permit" } })
    }

    // MARK: - Several bands

    @Test("Overlapping bands stack, and each keeps its own height")
    func overlappingBandsStack() throws {
        let days = self.days
        let week = Array(days.prefix(7))

        let long = self.band("Permit", from: week[0], through: week[6])
        let short = self.band("Trip", from: week[2], through: week[4], tint: .teal)

        let lanes = CKUtils.bandLanes(days: days, events: [long, short], calendar: self.calendar)

        for date in week {
            let column = try #require(lanes[date.midnight])

            #expect(column[0]?.id == long.id, "the long band must not move")
        }

        // The shorter one sits under it for the days they share, at one consistent height.
        for date in week[2...4] {
            let column = try #require(lanes[date.midnight])

            #expect(column.count == 2)
            #expect(column[1]?.id == short.id)
        }
    }

    @Test("A gap in a lane is a hole, not a closed-up space")
    func emptyLanesHoldTheirPlace() throws {
        let days = self.days
        let week = Array(days.prefix(7))

        // Two bands that never overlap: the first takes lane 0, the second is free to reuse it.
        let early = self.band("Early", from: week[0], through: week[1])
        let late = self.band("Late", from: week[4], through: week[5], tint: .orange)

        let lanes = CKUtils.bandLanes(days: days, events: [early, late], calendar: self.calendar)

        #expect(try #require(lanes[week[4].midnight])[0]?.id == late.id)

        // Nothing on either — trailing empties are trimmed, so the day's own events get the room.
        #expect(try #require(lanes[week[2].midnight]).isEmpty)
    }

    @Test("A band crossing a row boundary is laned per row")
    func lanesAreRecomputedPerWeek() throws {
        let days = self.days

        let crossing = self.band("Permit", from: days[5], through: days[9])
        let firstRowOnly = self.band("Trip", from: days[0], through: days[6], tint: .teal)

        let lanes = CKUtils.bandLanes(days: days, events: [crossing, firstRowOnly], calendar: self.calendar)

        // In the first row the trip started earlier, so it holds lane 0 and the permit sits under it.
        #expect(try #require(lanes[days[5].midnight])[1]?.id == crossing.id)

        // In the second row the trip is gone, and the permit is free to move up rather than
        // inheriting a gap from a week the reader can no longer see.
        #expect(try #require(lanes[days[7].midnight])[0]?.id == crossing.id)
    }

    @Test("No bands means no lanes, and no reserved space")
    func noBandsMeansNoLanes() {
        #expect(CKUtils.bandLanes(days: self.days, events: [], calendar: self.calendar).isEmpty)
    }
}

// MARK: - Runs

@Suite("Band runs — one view per unbroken stretch")
struct CKBandRunTests {

    private let calendar = Calendar.current

    /// A week starting on the reader's first weekday.
    private var week: [Date] {
        let today = Date().midnight
        let weekday = self.calendar.component(.weekday, from: today)
        let toStart = -((weekday - self.calendar.firstWeekday + 7) % 7)
        let start = self.calendar.date(byAdding: .day, value: toStart, to: today) ?? today

        return (0..<7).compactMap { self.calendar.date(byAdding: .day, value: $0, to: start) }
    }

    private func band(_ title: String, from: Date, through: Date) -> CKEvent {
        CKEvent(
            id: CKEventID(recordID: UUID(), facet: .trip),
            kind: .span(from: from, through: through),
            title: title,
            tint: .green,
            source: .trip(UUID())
        )
    }

    @Test("A band across the whole week is one run of seven, not seven runs of one")
    func aFullWeekIsOneRun() throws {
        let week = self.week
        let band = self.band("Permit", from: week[0], through: week[6])

        let runs = CKUtils.bandRuns(week: week, events: [band], calendar: self.calendar)

        // This is the whole point: a run is what the title gets to sit in. Seven runs of one
        // means seven labels each clipped to a single column, which is what "CAA OA…" was.
        #expect(runs.count == 1)
        #expect(runs[0].startIndex == 0)
        #expect(runs[0].length == 7)
    }

    @Test("A band that begins mid-week starts its run there")
    func aLateBandStartsWhereItStarts() throws {
        let week = self.week
        let band = self.band("Trip", from: week[3], through: week[5])

        let run = try #require(CKUtils.bandRuns(week: week, events: [band], calendar: self.calendar).first)

        #expect(run.startIndex == 3)
        #expect(run.length == 3)
    }

    @Test("A band running past the week is clipped to it")
    func aBandIsClippedToTheWeek() throws {
        let week = self.week
        let before = self.calendar.date(byAdding: .day, value: -10, to: week[0]) ?? week[0]
        let after = self.calendar.date(byAdding: .day, value: 10, to: week[6]) ?? week[6]

        let run = try #require(
            CKUtils.bandRuns(week: week, events: [self.band("Permit", from: before, through: after)],
                             calendar: self.calendar).first
        )

        #expect(run.startIndex == 0)
        #expect(run.length == 7)
    }

    @Test("Two bands in one lane are two runs, not one")
    func separateBandsAreSeparateRuns() {
        let week = self.week
        let early = self.band("Early", from: week[0], through: week[1])
        let late = self.band("Late", from: week[4], through: week[5])

        let runs = CKUtils.bandRuns(week: week, events: [early, late], calendar: self.calendar)

        // They share lane 0 because they never overlap, but a single run spanning the gap would
        // draw a bar across days neither of them covers.
        #expect(runs.count == 2)
        #expect(runs.allSatisfy { $0.lane == 0 })
        #expect(Set(runs.map(\.startIndex)) == [0, 4])
    }

    @Test("Overlapping bands run in their own lanes")
    func overlappingBandsRunInTheirOwnLanes() {
        let week = self.week
        let long = self.band("Permit", from: week[0], through: week[6])
        let short = self.band("Trip", from: week[2], through: week[4])

        let runs = CKUtils.bandRuns(week: week, events: [long, short], calendar: self.calendar)

        #expect(runs.count == 2)
        #expect(Set(runs.map(\.lane)) == [0, 1])
    }

    @Test("A run carries a stable identity, so the row is not rebuilt on every pass")
    func runsAreIdentifiable() {
        let week = self.week
        let band = self.band("Permit", from: week[0], through: week[6])

        let first = CKUtils.bandRuns(week: week, events: [band], calendar: self.calendar)
        let second = CKUtils.bandRuns(week: week, events: [band], calendar: self.calendar)

        #expect(first.map(\.id) == second.map(\.id))
    }
}

@Suite("Band reservations — space held clear where the bars actually are")
struct CKBandReservationTests {

    private let calendar = Calendar.current

    /// A week starting on the reader's first weekday.
    private var week: [Date] {
        let today = Date().midnight
        let weekday = self.calendar.component(.weekday, from: today)
        let toStart = -((weekday - self.calendar.firstWeekday + 7) % 7)
        let start = self.calendar.date(byAdding: .day, value: toStart, to: today) ?? today

        return (0..<7).compactMap { self.calendar.date(byAdding: .day, value: $0, to: start) }
    }

    private func band(_ title: String, from: Date, through: Date) -> CKEvent {
        CKEvent(
            id: CKEventID(recordID: UUID(), facet: .trip),
            kind: .span(from: from, through: through),
            title: title,
            tint: .green,
            source: .trip(UUID())
        )
    }

    private func runs(_ events: [CKEvent]) -> [CKBandRun] {
        CKUtils.bandRuns(week: self.week, events: events, calendar: self.calendar)
    }

    /// The bug this whole pair of functions exists for. Reported on an iPad 2026-09-02: a
    /// Tuesday carrying three deadlines and no band at all began two rows down, because a trip
    /// and a hotel ran across the following Saturday and Sunday.
    @Test("A day no band reaches reserves nothing")
    func anUntouchedDayReservesNothing() {
        let week = self.week
        let counts = CKUtils.bandRowCounts(
            runs: self.runs([
                self.band("Bamburgh", from: week[5], through: week[6]),
                self.band("The Castle Keep B&B", from: week[5], through: week[6])
            ]),
            columns: week.count
        )

        #expect(counts == [0, 0, 0, 0, 0, 2, 2])
    }

    /// The other half, and the reason this is not simply "how many bands are on this day": a bar
    /// in lane 1 is drawn at lane 1's height on every day it covers, so lane 0 has to stay clear
    /// beneath it even where nothing occupies it. Take that away and the bars stop being level,
    /// which is the whole point of assigning lanes for the row.
    @Test("A day under lane 1 alone still reserves the lane above it")
    func aHoleBeneathABandIsStillReserved() {
        let week = self.week
        let counts = CKUtils.bandRowCounts(runs: self.overlapping, columns: week.count)

        // The second band takes lane 1 because it overlaps the first, and it keeps that lane for
        // its whole length — including the days the first has already ended. Those days have a
        // hole at lane 0 and must still reserve two rows, or the bar jumps up a row mid-week.
        #expect(counts == [1, 1, 2, 2, 2, 2, 2])
    }

    @Test("Reserving counts lanes; counting counts bands")
    func reservingAndCountingAreDifferentNumbers() {
        let week = self.week
        let laid = self.overlapping

        // Friday sits under one bar, in lane 1: two rows held clear, one band actually there.
        // `bandRowCounts` answers "how far down does this day start", `bandCounts` answers "how
        // many bars are there" — and only the second belongs in "+ N more".
        #expect(CKUtils.bandRowCounts(runs: laid, columns: week.count)[5] == 2)
        #expect(CKUtils.bandCounts(runs: laid, columns: week.count)[5] == 1)
    }

    /// Two bands overlapping in the middle of the week, so the later one holds lane 1 across days
    /// where lane 0 is empty.
    private var overlapping: [CKBandRun] {
        let week = self.week

        return self.runs([
            self.band("Permit", from: week[0], through: week[3]),
            self.band("Trip", from: week[2], through: week[6])
        ])
    }

    @Test("Only the days a hidden band covers are told about it")
    func hiddenBandsAreCountedPerDay() {
        let week = self.week
        let laid = self.runs([
            self.band("Trip", from: week[0], through: week[6]),
            self.band("Permit", from: week[0], through: week[6]),
            self.band("Hotel", from: week[5], through: week[6])
        ])

        // Pretend the row could only draw two lanes: the third band is hidden, and only the two
        // days it actually covers should say "+ 1 more".
        let hidden = CKUtils.bandCounts(runs: laid.filter { $0.lane >= 2 }, columns: week.count)

        #expect(hidden == [0, 0, 0, 0, 0, 1, 1])
    }

    @Test("A run reaching past the last column does not read off the end")
    func aRunPastTheEndIsClamped() {
        let week = self.week
        let laid = self.runs([self.band("Trip", from: week[0], through: week[6])])

        // The month grid caps a short row at fewer than seven columns, and a run built for a
        // full week would otherwise index past it.
        #expect(CKUtils.bandRowCounts(runs: laid, columns: 3) == [1, 1, 1])
        #expect(CKUtils.bandRowCounts(runs: laid, columns: 0).isEmpty)
    }
}

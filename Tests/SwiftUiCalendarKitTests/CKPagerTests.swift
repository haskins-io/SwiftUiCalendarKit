// CKPagerTests.swift
//
// The three-page window behind the swipeable day and week strips — `CKPager`.

@testable import SwiftUiCalendarKit
import Foundation
import Testing

@Suite("Pager — always a page either side of the one you are on")
struct CKPagerTests {

    private func previous(_ page: Int) -> Int? { page - 1 }
    private func next(_ page: Int) -> Int? { page + 1 }

    @Test("The first window is the page before, the page, and the page after")
    func initialWindow() {
        #expect(CKPager.window(around: 10, previous: self.previous, next: self.next) == [9, 10, 11])
    }

    @Test("A neighbour that cannot be made is left out rather than invented")
    func missingNeighbours() {
        #expect(CKPager.window(around: 10, previous: { _ in nil }, next: self.next) == [10, 11])
        #expect(CKPager.window(around: 10, previous: { _ in nil }, next: { _ in nil }) == [10])
    }

    @Test("Landing in the middle changes nothing")
    func middleIsStable() {
        let slid = CKPager.recentre([9, 10, 11], at: 1, previous: self.previous, next: self.next)

        #expect(slid.pages == [9, 10, 11])
        #expect(slid.index == 1)
    }

    @Test("Swiping back to the first page adds one before it and drops the last")
    func swipeBack() {
        let slid = CKPager.recentre([9, 10, 11], at: 0, previous: self.previous, next: self.next)

        #expect(slid.pages == [8, 9, 10])
        #expect(slid.index == 1)
        #expect(slid.pages[slid.index] == 9)
    }

    @Test("Swiping forward to the last page adds one after it and drops the first")
    func swipeForward() {
        let slid = CKPager.recentre([9, 10, 11], at: 2, previous: self.previous, next: self.next)

        #expect(slid.pages == [10, 11, 12])
        #expect(slid.index == 1)
        #expect(slid.pages[slid.index] == 11)
    }

    @Test("An index outside the window, or a window too small to slide, is left alone")
    func degenerateInputs() {
        #expect(CKPager.recentre([9, 10, 11], at: 5, previous: self.previous, next: self.next).pages == [9, 10, 11])
        #expect(CKPager.recentre([Int](), at: 0, previous: self.previous, next: self.next).pages.isEmpty)
        #expect(CKPager.recentre([10], at: 0, previous: self.previous, next: self.next).pages == [10])
    }

    @Test("Paging days moves one calendar day at a time")
    func pagingDays() {
        let window = CKPager.window(around: Fixture.day(), previous: { $0.previousDate() }, next: { $0.nextDate() })
        let slid = CKPager.recentre(window, at: 2, previous: { $0.previousDate() }, next: { $0.nextDate() })

        #expect(window == [Fixture.day(-1), Fixture.day(0), Fixture.day(1)])
        #expect(slid.pages == [Fixture.day(0), Fixture.day(1), Fixture.day(2)])
    }

    @Test("Paging weeks moves one whole week at a time")
    func pagingWeeks() {
        let window = CKPager.window(
            around: Fixture.anchor.fetchWeek(),
            previous: { $0.first?.date.createPreviousWeek() },
            next: { $0.last?.date.createNextWeek() }
        )
        let firstDays = window.compactMap { $0.first?.date }

        #expect(window.count == 3)
        #expect(window.allSatisfy { $0.count == 7 })
        #expect(firstDays[1] == Fixture.week.first)
        #expect(Fixture.calendar.dateComponents([.day], from: firstDays[0], to: firstDays[1]).day == 7)
        #expect(Fixture.calendar.dateComponents([.day], from: firstDays[1], to: firstDays[2]).day == 7)
    }
}

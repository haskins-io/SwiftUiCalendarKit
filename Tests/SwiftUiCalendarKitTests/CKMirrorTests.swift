// CKMirrorTests.swift
//
// Right-to-left layout: each calendar surface, rendered left to right and right to left, should
// be the mirror image of itself. Rendered rather than inspected, because the layouts position
// things with offsets and a mistake there only shows up in where the pixels land.
//
// Events are tinted a colour nothing else in the calendar uses, so the comparison looks at the
// events alone and not at text, whose glyphs do not mirror. Every test also checks that the
// left-to-right render is *not* its own mirror image, or a symmetric fixture would pass
// whatever the layout did.
//
// Views that build their layout in a `.task` (the week and compact calendars) cannot be rendered
// in one pass, so their pieces are composed here the way those views compose them.

@testable import SwiftUiCalendarKit
import SwiftUI
import Testing

@Suite("Right to left — every surface is the mirror image of itself")
@MainActor
struct CKMirrorTests {

    /// A tint used by no part of the calendar's own chrome.
    private static let tint = Color(red: 0, green: 0.8, blue: 0.8)

    /// The tint, solid or washed out over white.
    private static func isTint(_ pixel: Bitmap.Pixel) -> Bool {
        pixel.alpha > 100
            && pixel.blue - pixel.red > 25
            && pixel.green - pixel.red > 25
            && abs(pixel.green - pixel.blue) < 20
    }

    /// Anti-aliasing keeps a true mirror slightly above zero.
    private static let tolerance = 0.05

    /// Below this, the fixture is too symmetric to tell a mirrored layout from an unmirrored one.
    private static let asymmetry = 0.3

    private let observer = CKCalendarObserver()

    /// Off-centre on purpose: a span starting early in the week, and an overlapping pair beside a
    /// lone event, so the overlap columns are uneven.
    private static let events: [CKEvent] = [
        CKEvent(kind: .span(from: Fixture.day(-2), through: Fixture.day(1)), title: "Trip", tint: Self.tint),
        CKEvent(kind: .timed(start: Fixture.at(10), end: Fixture.at(11)), title: "A", tint: Self.tint),
        CKEvent(kind: .timed(start: Fixture.at(10, 30), end: Fixture.at(12)), title: "B", tint: Self.tint),
        CKEvent(kind: .timed(start: Fixture.at(15), end: Fixture.at(16)), title: "C", tint: Self.tint)
    ]

    /// Renders `view` both ways and checks the tinted pixels mirror.
    private func expectMirrors(_ view: some View, sourceLocation: SourceLocation = #_sourceLocation) throws {
        let leftToRight = try #require(Bitmap.render(view), sourceLocation: sourceLocation)
        let rightToLeft = try #require(Bitmap.render(view, direction: .rightToLeft), sourceLocation: sourceLocation)

        let mismatch = try #require(
            leftToRight.mirrorMismatch(with: rightToLeft, where: Self.isTint),
            "nothing in the tint was drawn",
            sourceLocation: sourceLocation
        )
        let symmetry = try #require(leftToRight.mirrorMismatch(with: leftToRight, where: Self.isTint))

        #expect(mismatch < Self.tolerance, "right to left is not the mirror image", sourceLocation: sourceLocation)
        #expect(symmetry > Self.asymmetry, "fixture too symmetric to test", sourceLocation: sourceLocation)
    }

    // MARK: Large calendars

    @Test("Month: multi-day bars run across the mirrored days")
    func month() throws {
        let month = CKMonth(observer: self.observer, events: Self.events, date: .constant(Fixture.anchor))
            .frame(width: 700, height: 600)

        try self.expectMirrors(month)
    }

    @Test("Day: overlapping events take mirrored columns beside the hour labels")
    func dayGrid() throws {
        // As `CKTimelineDay` draws it, with the layout it builds for a 400-point view.
        let grid = CKUtils.generateEventViewData(date: Fixture.day(), events: Self.events, width: 345)

        let day = ZStack(alignment: .topLeading) {
            CKTimeline()

            ForEach(grid) { event in
                CKEventView(event, observer: self.observer)
            }
        }
        .frame(width: 400)

        try self.expectMirrors(day)
    }

    @Test("Week: overlapping events take mirrored columns within a day")
    func weekColumn() throws {
        // One day column of `CKTimelineWeek`, laid out for its width.
        let width: CGFloat = 100
        let grid = CKUtils.generateEventViewData(date: Fixture.day(), events: Self.events, width: width)

        let column = ZStack(alignment: .topLeading) {
            CKTimeline(showTime: false)
                .frame(width: width)

            ForEach(grid) { event in
                CKTimelineWeekEventView(event, observer: self.observer)
            }
        }
        .frame(width: width)

        try self.expectMirrors(column)
    }

    @Test("Day header: each weekday sits over its mirrored column")
    func dayHeader() throws {
        // Leading-aligned, as `CKMonth` places it. Compared by where the text columns are, since
        // the letters themselves do not mirror.
        let width: CGFloat = 700
        let header = VStack(alignment: .leading) {
            CKDayHeader(currentDate: .constant(Fixture.anchor), width: width, showTime: false, showDate: true)
        }
        .frame(width: width, height: 60, alignment: .topLeading)

        let leftToRight = try #require(Bitmap.render(header))
        let rightToLeft = try #require(Bitmap.render(header, direction: .rightToLeft))

        let columns = Self.centres(in: leftToRight, where: Self.isInk)
        let mirrored = Self.mirroredCentres(in: rightToLeft, where: Self.isInk)

        #expect(columns.count == 7)
        #expect(Self.matches(columns, mirrored), "\(columns) vs \(mirrored)")
    }

    // MARK: Compact calendars

    @Test("Compact day and week: overlapping events take mirrored columns")
    func compactGrid() throws {
        // As `CKCompactDay` and `CKCompactWeek` draw it, with the layout they build.
        let grid = CKUtils.generateEventViewData(date: Fixture.day(), events: Self.events, width: 340)

        let day = ZStack(alignment: .topLeading) {
            CKTimeline()
            CKCompactEventsView(eventData: grid, detail: { _ in EmptyView() })
        }
        .frame(width: 390)

        try self.expectMirrors(day)
    }

    @Test("Compact month: each day's event dot is under its own mirrored day")
    func compactMonth() throws {
        let month = CKMonthComponent(calendar: Fixture.calendar, date: .constant(Fixture.anchor), events: Self.events)
            .frame(width: 390)

        let leftToRight = try #require(Bitmap.render(month))
        let rightToLeft = try #require(Bitmap.render(month, direction: .rightToLeft))

        // Compared by centre rather than pixel by pixel: the grid's columns are a fractional
        // width, so a 5-point dot can land a pixel either side of its exact mirror.
        let isDot = { (pixel: Bitmap.Pixel) in
            pixel.alpha > 128 && pixel.green > 120 && pixel.green - pixel.red > 60 && pixel.green - pixel.blue > 60
        }

        let dots = Self.centres(in: leftToRight, where: isDot)
        let mirrored = Self.mirroredCentres(in: rightToLeft, where: isDot)

        // The 12th to the 15th, in one week row: off-centre, so a layout that did not mirror
        // would put them on the wrong side.
        #expect(dots.count == 4)
        #expect(Self.matches(dots, mirrored), "\(dots) vs \(mirrored)")
        let flipped = dots.map { Double(leftToRight.width) - $0 }.reversed()

        #expect(!Self.matches(dots, Array(flipped)), "fixture too symmetric to test")
    }

    // MARK: Helpers

    private static func isInk(_ pixel: Bitmap.Pixel) -> Bool {
        pixel.alpha > 128 && pixel.red < 120 && pixel.green < 120 && pixel.blue < 120
    }

    /// The horizontal centres of the runs of columns with matching pixels in them, left to right.
    ///
    /// Runs closer than a few points merge, so a word, or a name over its date, counts as one.
    private static func centres(in bitmap: Bitmap, where test: (Bitmap.Pixel) -> Bool) -> [Double] {
        let marked = (0..<bitmap.width).map { column in
            (0..<bitmap.height).contains { test(bitmap.pixel(x: column, y: $0)) }
        }

        let minimumGap = 6
        var centres: [Double] = []
        var start: Int?
        var last = 0

        for column in 0...bitmap.width {
            if column < bitmap.width, marked[column] {
                start = start ?? column
                last = column
            } else if let runStart = start, column - last >= minimumGap || column == bitmap.width {
                centres.append(Double(runStart + last + 1) / 2)
                start = nil
            }
        }

        return centres
    }

    /// `centres`, flipped left to right so they can be compared with a left-to-right render.
    private static func mirroredCentres(in bitmap: Bitmap, where test: (Bitmap.Pixel) -> Bool) -> [Double] {
        Self.centres(in: bitmap, where: test).map { Double(bitmap.width) - $0 }.reversed()
    }

    /// Whether two sets of centres agree to within a pixel and a half.
    private static func matches(_ lhs: [Double], _ rhs: [Double]) -> Bool {
        lhs.count == rhs.count && zip(lhs, rhs).allSatisfy { abs($0 - $1) <= 1.5 }
    }
}

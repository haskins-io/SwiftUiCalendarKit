// CKLocaleTests.swift
//
// The SwiftUI environment's locale reaches every piece of text the package draws:
// `.environment(\.locale, …)` changes the dates, times and the package's own words, not only the
// device's settings.
//
// Views are rendered with British English and with Egyptian Arabic in the environment, and the
// text has to come out differently. Arabic writes its digits, months and weekdays differently,
// and the machine running the tests is the same for both renders, so a view that formatted with
// the device's locale would draw the same text twice.

@testable import SwiftUiCalendarKit
import SwiftUI
import Testing

@Suite("Locale — text follows the environment's locale, not the device's")
@MainActor
struct CKLocaleTests {

    private static let english = Locale(identifier: "en_GB")
    private static let arabic = Locale(identifier: "ar_EG")

    /// Text, including the secondary-coloured kind most times and dates are drawn in.
    private static func isInk(_ pixel: Bitmap.Pixel) -> Bool {
        pixel.alpha > 60 && pixel.red < 200 && pixel.green < 200 && pixel.blue < 200
    }

    /// Well clear of anti-aliasing noise, well short of "every pixel changed".
    private static let threshold = 0.2

    private static let observer = CKCalendarObserver()

    private static let timed = Fixture.timed(Fixture.at(10), Fixture.at(11), "Planning")
    private static let deadline = Fixture.deadline(Fixture.at(9), "Invoice")
    private static let span = Fixture.span(Fixture.day(-1), Fixture.day(2), "Trip")
    private static let events = [Self.timed, Self.deadline, Self.span]

    /// Every view that formats a date or shows one of the package's strings, as the calendars
    /// compose them.
    ///
    /// Except three whose text `ImageRenderer` cannot draw, because it sits in a platform view:
    /// `CKAgenda` and `CKCompactAgenda` (a `List`) and `CKCompactEventView` (a `NavigationLink`).
    /// They format their dates the same way as the views here.
    private static let views: [(String, AnyView)] = {
        let grid = CKUtils.generateEventViewData(
            date: Fixture.day(),
            events: [Self.timed],
            width: 300,
            calendar: Fixture.calendar
        )

        return [
            ("hour labels", AnyView(CKTimeline().frame(width: 300))),
            ("day header", AnyView(
                CKDayHeader(currentDate: .constant(Fixture.anchor), width: 600, showTime: false, showDate: true)
                    .frame(width: 600, height: 60, alignment: .topLeading)
            )),
            ("calendar header", AnyView(
                CKCalendarHeader(currentDate: .constant(Fixture.anchor), addWeek: false)
                    .frame(width: 600)
            )),
            ("week number", AnyView(CKWeekOfYear(date: Fixture.anchor).showWeekNumbers(true).frame(width: 200))),
            // Narrow, so the label and not the line beside it is most of what is drawn.
            ("time indicator", AnyView(CKTimeIndicator(time: Fixture.at(10)).frame(width: 50))),
            ("compact month", AnyView(
                CKMonthComponent(calendar: Fixture.calendar, date: .constant(Fixture.anchor), events: Self.events)
                    .frame(width: 390)
            )),
            ("day event", AnyView(
                ZStack(alignment: .topLeading) {
                    ForEach(grid) { CKEventView($0, observer: Self.observer) }
                }
                .frame(width: 350, height: 1500, alignment: .topLeading)
            )),
            ("week event", AnyView(
                ZStack(alignment: .topLeading) {
                    ForEach(grid) { CKTimelineWeekEventView($0, observer: Self.observer) }
                }
                .frame(width: 350, height: 1500, alignment: .topLeading)
            )),
            ("list: timed", AnyView(CKListEventView(event: Self.timed).frame(width: 300))),
            ("list: deadline", AnyView(CKListEventView(event: Self.deadline).frame(width: 300))),
            ("list: span", AnyView(CKListEventView(event: Self.span).frame(width: 300))),
            ("month", AnyView(
                CKMonth(observer: Self.observer, events: Self.events, date: .constant(Fixture.anchor))
                    .frame(width: 700, height: 600)
            )),
            ("timeline day", AnyView(
                CKTimelineDay(observer: Self.observer, events: Self.events, date: .constant(Fixture.anchor))
                    .frame(width: 600, height: 600)
            )),
            ("timeline week", AnyView(
                CKTimelineWeek(observer: Self.observer, events: Self.events, date: .constant(Fixture.anchor))
                    .frame(width: 800, height: 600)
            )),
            ("compact day", AnyView(
                CKCompactDay(detail: { _ in EmptyView() }, events: Self.events, date: .constant(Fixture.anchor))
                    .frame(width: 390, height: 600)
            )),
            ("compact week", AnyView(
                CKCompactWeek(detail: { _ in EmptyView() }, events: Self.events, date: .constant(Fixture.anchor))
                    .frame(width: 390, height: 600)
            ))
        ]
    }()

    @Test("A view's text changes with the environment's locale", arguments: Self.views.map(\.0))
    func followsEnvironment(name: String) throws {
        let view = try #require(Self.views.first { $0.0 == name }?.1)

        let english = try #require(Bitmap.render(view, locale: Self.english))
        let arabic = try #require(Bitmap.render(view, locale: Self.arabic))

        let difference = try #require(english.mismatch(with: arabic, where: Self.isInk), "no text drawn")

        #expect(difference > Self.threshold, "\(name) drew the same text in both locales")
    }
}

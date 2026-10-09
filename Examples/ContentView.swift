//
//  SwiftUiCalendarKit.swift
//
//
//  Created by Mark Haskins on 16/04/2024.
//

import SwiftUI

struct ContentView: View {

    @Environment(\.horizontalSizeClass)
    private var horizontalSizeClass

    @State private var date = Date()

    @State private var mode: CKCalendarMode = .day
    @State private var showNewEventSheet = false

    @State private var observer = CKCalendarObserver()

    @State private var scrollRequest = 0

    /// The calendar handed to the calendars through the environment, to check week starts,
    /// month grids and month names without changing the simulator's settings.
    @State private var testCalendar: TestCalendar = .device

    private static let middleDateStart = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: Date()) ?? Date()
    private static let middleDateEnd = calendar.date(byAdding: .hour, value: 1, to: middleDateStart) ?? Date()

    private static let midEventStart = calendar.date(byAdding: .day, value: 1, to: middleDateStart) ?? Date()
    private static let midEventEnd = calendar.date(byAdding: .day, value: 1, to: middleDateEnd) ?? Date()

    private static let calendar = Calendar.current

    private static func at(hour: Int, minute: Int = 0, on day: Date = midEventStart) -> Date {
        calendar.date(bySettingHour: hour, minute: minute, second: 0, of: day) ?? day
    }

    private static func offset(days: Int, from date: Date) -> Date {
        calendar.date(byAdding: .day, value: days, to: date) ?? date
    }

    private static func preview(
        _ title: String,
        _ kind: CKEvent.Kind,
        systemImage: String = "",
        tint: Color = Color.green,
        tentative: Bool = false
    ) -> CKEvent {
        CKEvent(
            kind: kind,
            title: title,
            systemImage: systemImage,
            tint: tint,
            isTentative: tentative
        )
    }

    let events: [CKEvent] = [
        // Bands
        preview("Multi Day Event", .span(from: offset(days: -1, from: middleDateStart),
                                         through: offset(days: 3, from: middleDateEnd))),
        preview("All Day 1", .allDay(middleDateStart)),
        preview("All Day 2", .allDay(middleDateStart)),

        // Grid — including the overlapping cluster the column algorithm exists for
        preview("Event 2", .timed(start: offset(days: -1, from: middleDateStart),
                                  end: offset(days: -1, from: middleDateEnd))),
        preview("Event 3", .timed(start: middleDateStart, end: middleDateEnd)),
        preview("Event 6", .timed(start: midEventStart, end: midEventEnd), tentative: true),
        preview("Event 7", .timed(start: at(hour: 10), end: at(hour: 11))),
        preview("Event 8", .timed(start: at(hour: 10, minute: 30), end: at(hour: 11, minute: 30))),
        preview("Event 12", .timed(start: at(hour: 11), end: at(hour: 12))),
        preview("Event 9", .timed(start: at(hour: 11), end: at(hour: 11, minute: 30))),
        preview("Event 10", .timed(start: at(hour: 15, minute: 15), end: at(hour: 16, minute: 15))),
        preview("Event 11", .timed(start: offset(days: 4, from: middleDateStart),
                                   end: offset(days: 4, from: middleDateEnd))),

        // Markers — zero-length, and invisible under the old shape
        preview("Invoice INV-014 due", .deadline(at(hour: 9)), systemImage: "paperplane"),
        preview("Lens service due", .deadline(at(hour: 9, on: offset(days: 2, from: middleDateStart))),
                systemImage: "wrench.and.screwdriver")
    ]

    private var agenda: some View {
        CKAgenda(
            observer: observer,
            events: events,
            from: date,
            scrollRequest: scrollRequest
        )
    }

    private var compactAgenda: some View {
        CKCompactAgenda(
            detail: { event in EventDetail(event: event) },
            events: events,
            from: date,
            scrollRequest: scrollRequest
        )
    }

    private var day: some View {
        CKTimelineDay(
            observer: observer,
            events: events,
            date: $date
        )
    }

    private var dayCompact: some View {
        CKCompactDay(
            detail: { event in EventDetail(event: event) },
            events: events,
            date: $date
        )
    }

    private var week: some View {
        CKTimelineWeek(
            observer: observer,
            events: events,
            date: $date
        )
        .showTime(true)
        .workingHours(start: 7, end: 19)
        .currentDayColour(.blue)
    }

    private var weekCompact: some View {
        CKCompactWeek(
            detail: { event in EventDetail(event: event) },
            events: events,
            date: $date
        )
        .currentDayColour(.blue)
    }

    private var month: some View {
        CKMonth(
            observer: observer,
            events: events,
            date: $date
        )
    }

    private var monthCompact: some View {
        CKCompactMonth(
            detail: { event in EventDetail(event: event) },
            events: events,
            date: $date
        )
    }

    var body: some View {
        NavigationStack {
            VStack {
                month
            }
            .environment(\.calendar, testCalendar.calendar)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Picker("Calendar", selection: $testCalendar) {
                            ForEach(TestCalendar.allCases) { option in
                                Text(option.name).tag(option)
                            }
                        }
                    } label: {
                        Label("Calendar", systemImage: "calendar")
                    }
                }
            }

            if let event = observer.event {
                Text(event.title)
            }
        }
    }
}

/// Calendars worth testing against: two week starts, and the non-Gregorian calendars most
/// likely to break a month grid (different month lengths and month starts).
private enum TestCalendar: String, CaseIterable, Identifiable {
    case device
    case gregorianSunday
    case gregorianMonday
    case hebrew
    case islamic
    case persian
    case japanese
    case buddhist

    var id: Self { self }

    var name: String {
        switch self {
        case .device:
            "Device setting"

        case .gregorianSunday:
            "Gregorian, Sunday first"

        case .gregorianMonday:
            "Gregorian, Monday first"

        case .hebrew:
            "Hebrew"

        case .islamic:
            "Islamic (Umm al-Qura)"

        case .persian:
            "Persian"

        case .japanese:
            "Japanese"

        case .buddhist:
            "Buddhist"
        }
    }

    var calendar: Calendar {
        switch self {
        case .device:
                .autoupdatingCurrent

        case .gregorianSunday:
            Self.make(.gregorian, firstWeekday: 1)

        case .gregorianMonday:
            Self.make(.gregorian, firstWeekday: 2)

        case .hebrew:
            Self.make(.hebrew)

        case .islamic:
            Self.make(.islamicUmmAlQura)

        case .persian:
            Self.make(.persian)

        case .japanese:
            Self.make(.japanese)

        case .buddhist:
            Self.make(.buddhist)
        }
    }

    /// In the device's time zone, which the package assumes. Without `firstWeekday`, the week
    /// starts where the device's region starts it.
    private static func make(_ identifier: Calendar.Identifier, firstWeekday: Int? = nil) -> Calendar {
        var calendar = Calendar(identifier: identifier)
        calendar.timeZone = .autoupdatingCurrent
        calendar.locale = .autoupdatingCurrent
        calendar.firstWeekday = firstWeekday ?? Calendar.autoupdatingCurrent.firstWeekday
        return calendar
    }
}
#Preview {
    NavigationStack {
        ContentView()
    }
}


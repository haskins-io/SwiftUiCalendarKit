//
//  CKCompactWeek.swift
//
//  Created by Mark Haskins on 09/04/2024.
//

internal import Combine
import SwiftUI

/// `CKCompactWeek` can be used for showing a single day calendar on a compact screen size such as an iPhone.
///
///     CKCompactWeek(
///         detail: { event in EventDetail(event: event) },
///         events: events,
///         date: $date
///     )
///
/// - Parameter detail: The view that should be shown when an event in the Calendar is tapped.
/// - Parameter events: an array of events that conform to ``CKEvent``.
/// - Parameter date: The date for the calendar to show.

public struct CKCompactWeek<Detail: View>: View {

    @Environment(\.locale)
    private var locale

    @Environment(\.ckConfig)
    private var config

    @Environment(\.colorScheme)
    private var colorScheme

    @Binding private var date: Date

    @State private var headerMonth = Date()

    @State private var weekSlider: [[WeekDay]] = []
    @State private var currentWeekIndex: Int = 1

    @State private var calendarWidth: CGFloat = .zero

    /// Computed off the main actor by `CKLayoutBuilder`. This used to be built in `body` inside
    /// a `GeometryReader`, so every size change re-ran an O(n²) overlap scan on the main actor.
    @State private var layout = CKLayout()

    @State private var timelinePosition = 0.0
    @State private var time = Date()

    private let detail: (CKEvent) -> Detail
    private var events: [CKEvent]
    private let calendar = Calendar.current

    private let timer: Publishers.Autoconnect<Timer.TimerPublisher>

    public init(
        @ViewBuilder detail: @escaping (CKEvent) -> Detail,
        events: [CKEvent],
        date: Binding<Date>
    ) {
        self.detail = detail
        self.events = events

        self._date = date
        self._headerMonth = State(initialValue: date.wrappedValue)

        self.timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
        _timelinePosition = State(initialValue: CKUtils.currentTimelinePosition())
    }
    public var body: some View {

        // Stacked, not `.safeAreaInset`: an inset only moves the safe area, and on a day with no
        // all-day rows the timeline's `ScrollView` is the top view, so it extended up under the
        // header and the hour grid was drawn behind it.
        VStack(spacing: 0) {
            headerView()
            timelineView()
        }
        .background(colorScheme == .dark ? Color.black : Color.white)
        .onAppear(perform: {
            calcWeekSliders(currentDate: date)
        })
        .onChange(of: date, initial: false) {
            headerMonth = date
            weekSlider.removeAll()
            calcWeekSliders(currentDate: date)
        }
        .task(id: CKLayoutRequest(dates: [date], events: events, width: calendarWidth - 50)) {
            layout = await CKLayoutBuilder.day(date: date, events: events, width: calendarWidth - 50)
        }
        .onChange(of: currentWeekIndex, initial: false) {
            paginateWeek()
        }
    }

    /// - Timeline View
    @ViewBuilder
    private func timelineView() -> some View {

        // A `GeometryReader`, not `.onGeometryChange` on the content — see the note in `CKMonth`
        // for why measuring the view that sizes itself from the result locks up. `initial: true`
        // is the part that was missing: `onChange` reports *changes*, and a size that is right
        // from the first layout pass never changes, so the width stayed `.zero` and
        // `CKLayoutBuilder` returned an empty layout for every event.
        GeometryReader { geometry in

            VStack(alignment: .leading, spacing: 0) {

                CKCompactDayEventsView(layout: layout, detail: detail)

                ScrollView {
                    timelineEvents()
                }
                .defaultScrollAnchor(.center)
            }
            .onChange(of: geometry.size, initial: true) { _, newSize in
                guard newSize.width > 0 else {
                    return
                }

                calendarWidth = newSize.width
            }
        }
    }

    @ViewBuilder
    private func timelineEvents() -> some View {

        ZStack(alignment: .topLeading) {

            CKTimeline()

            CKCompactEventsView(eventData: layout.grid, detail: detail)

            if config.showTime {
                CKTimeIndicator(time: time)
                    .offset(x: 0, y: timelinePosition)
            }
        }
        .onReceive(timer) { _ in
            guard config.showTime else {
                return
            }
            if calendar.component(.second, from: Date()) == 0 {
                time = Date()
                timelinePosition = CKUtils.currentTimelinePosition()
            }
        }
    }

    /// - Header View
    @ViewBuilder
    private func headerView() -> some View {

        VStack(alignment: config.headingAlignment) {

            HStack {
                Text(headerMonth.formatted(.dateTime.month(.wide).year().locale(self.locale)))

                Spacer()

                // Navigated by swiping the week row, which is fine until you are months out and
                // want to come back. Compact Month has always had its own way home; this did not.
                CKDateStepper(date: $date, component: .weekOfYear)
                    .padding(.trailing, 10)
            }
            .padding(.leading, 10)
            .padding(.top, 5)
            .font(.title)

            CKWeekOfYear(date: date)

            TabView(selection: $currentWeekIndex) {
                ForEach(weekSlider.indices, id: \.self) { index in
                    let week = weekSlider[index]
                    weekRow(week)
                        .tag(index)
                }
            }
#if !os(macOS)
            .tabViewStyle(.page(indexDisplayMode: .never))
#endif
            // 82 rather than 70: the moon glyph added a row to each column, and a `TabView`
            // with a fixed height clips what it cannot fit rather than growing.
            .frame(height: 82)
            .padding(5)
        }
    }

    /// - Week Row
    @ViewBuilder
    private func weekRow(_ week: [WeekDay]) -> some View {

        HStack(spacing: 0) {

            ForEach(week) { day in
                weekRowView(day: day)
            }
        }
    }

    @ViewBuilder
    private func weekRowView(day: WeekDay) -> some View {

        let status = calendar.isDate(day.date, inSameDayAs: Date())

        VStack(spacing: 4) {

            CKWeekdayLabel(date: day.date)

            ZStack {
                RoundedRectangle(cornerRadius: 5)
                    .fill(cellColour(day: day))
                    .frame(width: 27, height: 27)

                Text(day.date.formatted(.dateTime.day(.twoDigits).locale(self.locale)))
                    .foregroundColor(status ? Color.white : .primary)
            }
        }
        .hAlign(.center)
        .contentShape(.rect)
        .onTapGesture {
            withAnimation(.snappy) {
                date = day.date
            }
        }
    }

    func cellColour(day: WeekDay) -> Color {
        return calendar.isDate(day.date, inSameDayAs: Date()) ?
        config.currentDayColour :
        calendar.isDate(day.date, inSameDayAs: date) ?
        Color.blue.opacity(0.10) :
            .clear
    }
}

extension CKCompactWeek {

    /// Slides the window as soon as a swipe lands on an end page, then selects that week's
    /// first day, as `CKCompactDay` does for days.
    ///
    /// This used to wait for the row's global `minX` to reach exactly 5 (the strip's padding)
    /// before sliding. That only held when the strip started at the screen's leading edge, so in
    /// a sidebar, a split view or any inset the window never slid and paging stopped.
    private func paginateWeek() {
        let slid = CKPager.recentre(
            weekSlider,
            at: currentWeekIndex,
            previous: { $0.first?.date.createPreviousWeek() },
            next: { $0.last?.date.createNextWeek() }
        )

        weekSlider = slid.pages
        currentWeekIndex = slid.index

        guard weekSlider.indices.contains(currentWeekIndex),
              let first = weekSlider[currentWeekIndex].first else {
            return
        }

        headerMonth = first.date
        date = first.date
    }

    private func calcWeekSliders(currentDate: Date) {
        if weekSlider.isEmpty {
            weekSlider = CKPager.window(
                around: currentDate.fetchWeek(),
                previous: { $0.first?.date.createPreviousWeek() },
                next: { $0.last?.date.createNextWeek() }
            )
        }
    }
}

#Preview {
    NavigationView {
        CKCompactWeek(
            detail: { _ in EmptyView() },
            events: testEvents,
            date: .constant(Date())
        )
        .showWeekNumbers(true)
        .workingHours(start: 9, end: 17)
    }
}

/// Laid out and formatted as for an Arabic reader: right to left, with Arabic digits, months and
/// weekdays. The package's own words stay English until it has an Arabic translation.
#Preview("Arabic, right to left") {
    NavigationView {
        CKCompactWeek(
            detail: { _ in EmptyView() },
            events: testEvents,
            date: .constant(Date())
        )
        .showWeekNumbers(true)
        .workingHours(start: 9, end: 17)
    }
    .environment(\.locale, Locale(identifier: "ar"))
    .environment(\.layoutDirection, .rightToLeft)
}

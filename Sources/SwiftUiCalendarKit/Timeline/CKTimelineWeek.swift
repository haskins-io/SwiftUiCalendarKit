//
//  CKTimelineWeek.swift
//
//  Created by Mark Haskins on 09/04/2024.
//

internal import Combine
import SwiftUI

/// `CKTimelineWeek` can be used for showing a single day calendar on a compact screen size such as an iPhone.
///
///     CKTimelineWeek(
///         observer: CKCalendarObserver(),
///         events: events,
///         date: $date
///     )
///
/// - Parameter observer: Listen to this to be notified when an event is tapped/clicked
/// - Parameter events: an array of events that conform to ``CKEvent``.
/// - Parameter date: The date for the calendar to show.

public struct CKTimelineWeek: View {

    @Environment(\.ckConfig)
    private var config

    @Environment(\.colorScheme)
    private var colorScheme

    @State var observer: CKCalendarObserver

    @Binding private var calendarDate: Date

    @State var columnWidth: CGFloat = .zero

    /// Computed off the main actor by `CKLayoutBuilder`, never in `body`.
    @State private var layout = CKLayout()

    @State private var timelinePosition = 0.0
    @State private var time = Date()

    private var events: [CKEvent]

    private let timer: Publishers.Autoconnect<Timer.TimerPublisher>

    var calendar = Calendar.current

    /// Wide enough for "00:00" at `.caption`. The labels no longer wrap at any size — they
    /// `fixedSize` past this if they have to — but the column arithmetic still needs a sane
    /// figure to subtract, or the seven day columns claim space the timebar is using.
    var timebarWidth: CGFloat = 52

    /// One lane of the band row. Named because an empty lane has to match a full one exactly, or
    /// the bars below it stop lining up.
    let bandHeight: CGFloat = 22

    /// The gap between stacked bands. Named because `bandRow` uses it in two places — the row's
    /// own height and each lane's offset — and they cannot be allowed to drift apart.
    let bandSpacing: CGFloat = 2

    public init(
        observer: CKCalendarObserver,
        events: [CKEvent],
        date: Binding<Date>
    ) {
        self._observer = .init(wrappedValue: observer)
        self.events = events
        self._calendarDate = date

        self.timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
        _timelinePosition = State(initialValue: CKUtils.currentTimelinePosition())
    }

    public var body: some View {

        let week = calendarDate.fetchWeek()

        // Bucketed once here rather than filtered inside each of the seven columns, which walked
        // the whole week's events per column.
        let gridByDay = Dictionary(grouping: layout.grid) { $0.start.midnight }

        // Laid out for the row rather than sorted per day, so a band sits at the same height in
        // every column it crosses and reads as one bar — see `CKUtils.bandLanes`.
        let bandRuns = CKUtils.bandRuns(week: week.map(\.date), events: layout.bands, calendar: calendar)

        // The day's own whole-day items — a one-day all-day event, or a deadline. Bucketed per
        // column here so the all-day area can stack each column's chips under whatever bands
        // actually reach that column.
        let singleDay = layout.singleDayBands(in: calendar) + layout.markers
        let chips = week.map { day in
            singleDay.filter { calendar.isDate($0.startDate, inSameDayAs: day.date) }
        }

        // A `GeometryReader`, not `.onGeometryChange` on the content — see the note in `CKMonth`.
        // The columns are sized *from* `columnWidth`, so measuring the view that holds them feeds
        // its own output back into its input. `initial: true` is what was missing: `onChange`
        // reports changes, and a size that is right from the first pass never changes.
        GeometryReader { geometry in

            VStack(spacing: 0) {

                CKCalendarHeader(currentDate: $calendarDate, addWeek: true)

                CKWeekOfYear(date: calendarDate).padding(.leading, 10)

                // No horizontal spacing. A 1pt gap between columns is what drew a white line
                // through every band, and the separators are already there — `GridOverlayModifier`
                // and `CKTimeline` each draw their own trailing rule.
                Grid(horizontalSpacing: 0, verticalSpacing: 0) {
                    GridRow(alignment: .top) {
                        calendarHeader(week: week)
                    }
                }

                Divider()

                // Outside the `Grid`, deliberately. A band is one view spanning several columns,
                // and a `GridRow` can only give it one cell — which is what clipped the title to
                // Monday while the wash ran the width of the week. The offsets land on the same
                // boundaries the grid uses, because `timebarWidth` and `columnWidth` are exact.
                //
                // Bands and single-day chips share one area rather than sitting in two stacked
                // rows: as two rows, every column's chips began below the deepest band in the
                // week, so a Tuesday with three deadlines and no band started two blank rows
                // down because a trip ran across the weekend.
                allDayArea(runs: bandRuns, chips: chips, week: week)

                Divider().frame(height: 2).overlay(.black)

                ScrollView {
                    // Zero here too, or the hour grid's columns sit seven points out from the
                    // header's and nothing above the rule lines up with anything below it.
                    Grid(horizontalSpacing: 0) {
                        GridRow {
                            showTimes()

                            ForEach(week) { weekDay in
                                dayView(
                                    events: gridByDay[weekDay.date.midnight] ?? [],
                                    date: weekDay.date
                                )
                            }
                        }
                    }
                }
                .defaultScrollAnchor(.center)
            }
            .background(colorScheme == .dark ? Color.black : Color.white)
            .onReceive(timer) { _ in
                guard config.showTime else {
                    return
                }
                if calendar.component(.second, from: Date()) == 0 {
                    time = Date()
                    timelinePosition = CKUtils.currentTimelinePosition()
                }
            }
            .task(id: CKLayoutRequest(dates: [calendarDate], events: events, width: columnWidth)) {
                layout = await CKLayoutBuilder.week(date: calendarDate, events: events, width: columnWidth)
            }
            .onChange(of: geometry.size, initial: true) { _, newSize in
                guard newSize.width > 0 else {
                    return
                }

                // Exact, now that the columns are contiguous: the timebar plus seven equal days
                // is the whole width. The old `- 6` was compensating for seven 1pt gaps and was
                // one short, which is why the band row sat inset from its own column.
                columnWidth = (newSize.width - timebarWidth) / 7
            }
        }
    }

    @ViewBuilder
    private func calendarHeader(week: [WeekDay]) -> some View {

        Color.clear
            .gridCellUnsizedAxes([.horizontal, .vertical])
            .frame(minWidth: timebarWidth, idealWidth: timebarWidth, maxWidth: timebarWidth)

        ForEach(week, id: \.id) { weekDay in

            VStack(alignment: .center, spacing: 0) {
                Text(weekDay.string.prefix(3))
                ZStack {
                    RoundedRectangle(cornerRadius: 5)
                        .fill(weekDay.date.isToday ? Color.blue.opacity(0.10) : Color.clear)
                        .frame(width: 27, height: 27)

                    Text(weekDay.date.formatted(.dateTime.day(.twoDigits)))
                }
            }
            .frame(minWidth: columnWidth, idealWidth: columnWidth, maxWidth: columnWidth)
            .modifier(GridOverlayModifier())
        }
    }

    @ViewBuilder
    private func showTimes() -> some View {

        VStack(alignment: .leading, spacing: 0) {
            ForEach(0..<24) { hour in
                HStack {
                    // See `CKTimeline`: a fixed width plus a Dynamic Type font wraps the label.
                    Text(String(format: "%02d:00", hour))
                        .font(.caption)
                        .monospacedDigit()
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
                    // Inside the frame, not outside it. Trailing padding on the `HStack` made
                    // this column five points wider than the one the band rows use, and the
                    // two grids then disagreed about where every day column began.
                        .padding(.trailing, 5)
                        .frame(width: timebarWidth, alignment: .trailing)
                }
                .frame(height: CKTimeline.hourHeight)
            }
        }
        .padding(0)
    }

    @ViewBuilder
    private func dayView(events: [CKEventViewData], date: Date) -> some View {

        ZStack(alignment: .topLeading) {
            CKTimeline(showTime: false)
                .frame(minWidth: columnWidth, idealWidth: columnWidth, maxWidth: columnWidth)

            if config.showTime {
                CKTimeIndicator(date: date, time: time, showTime: false)
                    .offset(x: 0, y: timelinePosition)
            }

            addEvents(eventData: events)
        }
    }

    @ViewBuilder
    private func addEvents(eventData: [CKEventViewData]) -> some View {
        ForEach(eventData) { event in
            CKTimelineWeekEventView(event, observer: observer)
        }
    }
}

#Preview {
    CKTimelineWeek(
        observer: CKCalendarObserver(),
        events: testEvents,
        date: .constant(Date())
    )
    .showWeekNumbers(true)
    .workingHours(start: 9, end: 17)
}

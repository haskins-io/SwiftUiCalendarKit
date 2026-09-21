//
//  CKTimelineDay.swift
//
//  Created by Mark Haskins on 03/04/2024.
//

internal import Combine
import SwiftUI

/// `CKTimelineDay` can be used for showing a single day calendar on a compact screen size such as an iPhone.
///
///     CKTimelineDay(
///         observer: CKCalendarObserver(),
///         events: events,
///         date: $date
///     )
///
/// - Parameter observer: Listen to this to be notified when an event is tapped/clicked
/// - Parameter events: an array of events that conform to ``CKEvent``.
/// - Parameter date: The date for the calendar to show.

public struct CKTimelineDay: View {

    @Environment(\.ckConfig)
    private var config

    @Environment(\.colorScheme)
    private var colorScheme

    @State var observer: CKCalendarObserver

    @Binding private var date: Date

    @State private var timelinePosition = 0.0
    @State private var time = Date()

    @State private var calendarWidth: CGFloat = .zero

    /// Computed off the main actor by `CKLayoutBuilder`, never in `body`.
    @State private var layout = CKLayout()

    private var events: [CKEvent]
    private let calendar = Calendar.current

    private let timer: Publishers.Autoconnect<Timer.TimerPublisher>

    init(
        observer: CKCalendarObserver,
        events: [CKEvent],
        date: Binding<Date>
    ) {
        self._observer = .init(wrappedValue: observer)
        self.events = events
        self._date = date

        self.timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
        _timelinePosition = State(initialValue: CKUtils.currentTimelinePosition())
    }

    public var body: some View {

        // A `GeometryReader`, not `.onGeometryChange` on the content — see the note in `CKMonth`
        // for why measuring the view that sizes itself from the result locks up. `initial: true`
        // is the part that was missing: `onChange` reports *changes*, and a size that is right
        // from the first layout pass never changes, so the width stayed `.zero` and
        // `CKLayoutBuilder` returned an empty layout for every event.
        GeometryReader { geometry in

            VStack(alignment: .leading, spacing: 2) {

                HStack {
                    Text(date.formatted(.dateTime.day().month(.wide))).bold()

                    Text(date.formatted(.dateTime.year()))
                }
                .padding(.leading, 10)
                .padding(.top, 5)
                .font(.title)

                HStack {
                    Text(date.formatted(.dateTime.weekday(.wide))).padding(.leading, 10)

                    Spacer()

                    CKWeekOfYear(date: date)

                    // Week and Month have had this since the beginning, inside
                    // `CKCalendarHeader`. The day view never did, and with no pager here that
                    // left iPad and macOS with no way to reach another day from the day view.
                    CKDateStepper(date: $date, component: .day)
                        .padding(.horizontal, 12)
                }

                Divider().padding([.leading, .trailing], 10)

                dayView()
            }
            .background(colorScheme == .dark ? Color.black : Color.white)
            // Touch keeps its swipe; the stepper is what makes the view usable without one.
            // A horizontal drag only — a vertical one belongs to the hour grid's scroll view.
            .gesture(
                DragGesture(minimumDistance: 30)
                    .onEnded { value in
                        guard abs(value.translation.width) > abs(value.translation.height) else {
                            return
                        }

                        let days = value.translation.width < 0 ? 1 : -1

                        withAnimation {
                            date = Calendar.current.date(byAdding: .day, value: days, to: date) ?? date
                        }
                    }
            )
            .task(id: CKLayoutRequest(dates: [date], events: events, width: calendarWidth - 55)) {
                layout = await CKLayoutBuilder.day(date: date, events: events, width: calendarWidth - 55)
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
    private func dayView() -> some View {

        dayStrip()

        ScrollView {

            ZStack(alignment: .topLeading) {

                CKTimeline()

                addEvents()

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
        .defaultScrollAnchor(.center)
    }

    /// The strip above the hour grid: what occupies the day, and what is due on it.
    ///
    /// Read from the band and marker lanes rather than filtered out of the grid's view data.
    /// `generateEventViewData` returns the `.grid` lane only, so an all-day shoot or an invoice
    /// due date was never in that array to be found — filtering it left this strip permanently
    /// empty without erroring.
    @ViewBuilder
    private func dayStrip() -> some View {
        VStack(spacing: 0) {
            ForEach(layout.bands + layout.markers) { event in
                CKDayEventView(event, observer: observer, width: calendarWidth)
            }
        }
    }

    /// The hour grid. Everything here is `.timed` and on this day by construction.
    @ViewBuilder
    private func addEvents() -> some View {
        ForEach(layout.grid) { event in
            CKEventView(event, observer: observer)
        }
    }
}

#Preview {
    CKTimelineDay(
        observer: CKCalendarObserver(),
        events: testEvents,
        date: .constant(Date())
    )
    .showWeekNumbers(true)
    .workingHours(start: 9, end: 17)
}

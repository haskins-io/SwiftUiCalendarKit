//
//  CKCompactDay.swift
//  
//
//  Created by Mark Haskins on 15/04/2024.
//

internal import Combine
import SwiftUI

/// `CKCompactDay` can be used for showing a single day calendar on a compact screen size such as an iPhone.
///
///     CKCompactDay(
///         detail: { event in EventDetail(event: event) },
///         events: events,
///         date: $date
///     )
///
/// - Parameter detail: The view that should be shown when an event in the Calendar is tapped.
/// - Parameter events: an array of events that conform to ``CKEvent``.
/// - Parameter date: The date for the calendar to show.

public struct CKCompactDay<Detail: View>: View {

    @Environment(\.ckConfig)
    private var config

    @Environment(\.colorScheme)
    private var colorScheme

    @Binding private var currentDate: Date

    @State private var headerDay = Date()

    @State private var daySlider: [Date] = []
    @State private var currentDayIndex: Int = 1
    @State private var createDay: Bool = false

    @State private var calendarWidth: CGFloat = .zero

    /// One layout per page of the day slider, so a swipe lands on a laid-out day rather than an
    /// empty one. Computed off the main actor by `CKLayoutBuilder`, never in `body`.
    @State private var layouts: [Date: CKLayout] = [:]

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
        self._currentDate = date

        self._headerDay = State(initialValue: date.wrappedValue)

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

                header()

                Divider().padding([.leading, .trailing], 10)

                timeline(width: calendarWidth)
            }
            .background(colorScheme == .dark ? Color.black : Color.white)
            .onAppear(perform: {
                calcDaySliders(newDate: currentDate)
            })
            .onChange(of: currentDate, initial: false) {
                headerDay = currentDate
                daySlider.removeAll()
                calcDaySliders(newDate: currentDate)
            }
            .onChange(of: currentDayIndex, initial: false) {
                updateSliders()
            }
            .task(id: CKLayoutRequest(dates: daySlider, events: events, width: calendarWidth - 50)) {
                layouts = await CKLayoutBuilder.days(daySlider, events: events, width: calendarWidth - 50)
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
    private func header() -> some View {

        VStack(alignment: .leading) {
            HStack {
                Text(headerDay.formatted(.dateTime.day().month(.wide)))
                    .bold()
                Text(headerDay.formatted(.dateTime.year()))
            }
            .padding(.leading, 10)
            .padding(.top, 5)
            .font(.title)

            HStack(alignment: .center) {
                Text(headerDay.formatted(.dateTime.weekday(.wide))).padding(.leading, 10)

                Spacer()
                CKWeekOfYear(date: currentDate)

                // The same control the wide day view and both grids use. The swipe still works;
                // this is what makes the three sizes navigate alike.
                CKDateStepper(date: $currentDate, component: .day)
                    .padding(.trailing, 10)
            }
        }
    }

    @ViewBuilder
    private func timeline(width: CGFloat) -> some View {

        TabView(selection: $currentDayIndex) {
            ForEach(daySlider.indices, id: \.self) { index in
                let day = daySlider[index]
                dayView(day)
                    .tag(index)
            }
        }
#if !os(macOS)
        .tabViewStyle(.page(indexDisplayMode: .never))
#endif
        .padding(0)
    }

    @ViewBuilder
    private func dayView(_ date: Date) -> some View {

        let layout = layouts[date.midnight] ?? CKLayout()

        VStack(spacing: 0) {

            CKCompactDayEventsView(layout: layout, detail: detail)

            ScrollView {

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
            .defaultScrollAnchor(.center)
        }
    }
}

extension CKCompactDay {

    private func updateSliders() {
        if currentDayIndex == 0 {
            if let firstDate = daySlider.first {
                daySlider.insert(firstDate.previousDate(), at: 0)
                daySlider.removeLast()
                currentDayIndex = 1
            }
        } else if currentDayIndex == daySlider.count - 1 {
            if let lastDate = daySlider.last {
                daySlider.append(lastDate.nextDate())
                daySlider.removeFirst()
                currentDayIndex = daySlider.count - 2
            }
        }

        headerDay = daySlider[currentDayIndex]
        currentDate = headerDay
    }

    private func calcDaySliders(newDate: Date) {
        if daySlider.isEmpty {
            daySlider.append(newDate.previousDate())
            daySlider.append(newDate)
            daySlider.append(newDate.nextDate())
        }
    }
}

#Preview {

    NavigationView {
        CKCompactDay(
            detail: { _ in EmptyView() },
            events: testEvents,
            date: .constant(Date())
        )
        .workingHours(start: 9, end: 17)
    }
}

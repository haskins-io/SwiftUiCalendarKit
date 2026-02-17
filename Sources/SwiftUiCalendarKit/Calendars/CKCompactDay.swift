//
//  CKCompactDay.swift
//  
//
//  Created by Mark Haskins on 15/04/2024.
//

import Combine
import SwiftUI

///
/// CKCompactDay
///
/// This Calendar type is used for showing a single day on a compact screen size such as an iPhone
///
/// - Paramters
///   - detail: The view that should be shown when an event in the Calendar is tapped.
///   - events: an array of events that conform to CKEventSchema
///   - date: The date for the calendar to show
///
public struct CKCompactDay<Detail: View>: View {

    @Environment(\.ckConfig)
    private var config

    @Binding private var currentDate: Date

    @State private var headerDay = Date()

    @State private var daySlider: [Date] = []
    @State private var currentDayIndex: Int = 1
    @State private var createDay: Bool = false

    private let detail: (any CKEventSchema) -> Detail
    private var events: [any CKEventSchema]
    private let calendar = Calendar.current

    @State private var timelinePosition = 0.0
    @State private var time = Date()
    private let timer: Publishers.Autoconnect<Timer.TimerPublisher>

    public init(
        @ViewBuilder detail: @escaping (any CKEventSchema) -> Detail,
        events: [any CKEventSchema],
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

        GeometryReader { proxy in

            VStack(alignment: .leading) {

                header()

                Divider().padding([.leading, .trailing], 10)

                timeline(width: proxy.size.width - 55)
            }
            .onAppear(perform: {
                calcDaySliders(newDate: currentDate)
            })
            .onChange(of: currentDate, initial: false) {
                headerDay = currentDate
                daySlider.removeAll()
                calcDaySliders(newDate: currentDate)
            }
            .onChange(of: currentDayIndex, initial: false) {

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

            HStack {
                Text(headerDay.formatted(.dateTime.weekday(.wide))).padding(.leading, 10)
                CKWeekOfYear(date: currentDate)
            }
        }
    }

    @ViewBuilder
    private func timeline(width: CGFloat) -> some View {

        TabView(selection: $currentDayIndex) {
            ForEach(daySlider.indices, id: \.self) { index in
                let day = daySlider[index]
                dayView(day, width)
                    .tag(index)
            }
        }
    }

    @ViewBuilder
    private func dayView(_ date: Date, _ width: CGFloat) -> some View {

        let eventData = CKUtils.generateEventViewData(
            date: date,
            events: events,
            width: width - 65
        )

        VStack(spacing: 0) {

            CKCompactDayEventsView(date: date, eventData: eventData, detail: detail)

            ScrollView {

                ZStack(alignment: .topLeading) {

                    CKTimeline()

                    CKCompactEventsView(date: date, eventData: eventData, detail: detail)

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
                .padding(5)
            }
            .defaultScrollAnchor(.center)
        }
    }

    @ViewBuilder
    private func addAllDayEvents(eventData: [CKEventViewData], width: CGFloat) -> some View {
        VStack(spacing: 0) {
            ForEach(eventData, id: \.anyHashableID) { event in
                if calendar.isDate(event.event.startDate, inSameDayAs: currentDate) && event.allDay {
                    CKCompactDayEventView(
                        event,
                        detail: detail
                    )
                }
            }
        }
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
        .showWeekNumbers(true)
    }
}

//
//  CKTimelineDay.swift
//
//  Created by Mark Haskins on 03/04/2024.
//

import Combine
import SwiftUI

///
/// CKTimelineDay
///
/// This Calendar type is used for showing a single day on a large screen size such as an iPad or Mac
///
/// - Paramters
///   - observer: Listen to this to be notified when an event is tapped/clicked
///   - events: an array of events that conform to CKEventSchema
///   - date: The date for the calendar to show
///
public struct CKTimelineDay: View {

    @Environment(\.ckConfig)
    private var config

    @ObservedObject var observer: CKCalendarObserver

    @Binding private var date: Date

    @State private var timelinePosition = 0.0
    @State private var time = Date()

    @State private var calendarWidth: CGFloat = .zero

    private var events: [any CKEventSchema]
    private let calendar = Calendar.current

    private let timer: Publishers.Autoconnect<Timer.TimerPublisher>

    public init(
        observer: CKCalendarObserver,
        events: [any CKEventSchema],
        date: Binding<Date>
    ) {
        self._observer = .init(wrappedValue: observer)
        self.events = events
        self._date = date

        self.timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
        _timelinePosition = State(initialValue: CKUtils.currentTimelinePosition())
    }

    public var body: some View {

        GeometryReader { geometry in

            Color.clear
                .onChange(of: geometry.size) { _, newSize in
                    guard newSize.width > 0, newSize.height > 0 else {
                        return
                    }

                    calendarWidth = newSize.width
                }

            if calendarWidth != .zero {

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
                    }

                    Divider().padding([.leading, .trailing], 10)

                    dayView()
                }
            }
        }
    }

    @ViewBuilder
    private func dayView() -> some View {

        let eventData = CKUtils.generateEventViewData(
            date: date,
            events: events,
            width: calendarWidth - 55
        )

        addAllDayEvents(eventData: eventData)

        ScrollView {

            ZStack(alignment: .topLeading) {

                CKTimeline()

                addEvents(eventData: eventData)

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

    @ViewBuilder
    private func addAllDayEvents(eventData: [CKEventViewData]) -> some View {
        VStack(spacing: 0) {
            ForEach(eventData, id: \.anyHashableID) { event in
                if calendar.isDate(event.event.startDate, inSameDayAs: date) && event.allDay {
                    CKDayEventView(
                        event,
                        observer: observer,
                        weekView: false,
                        width: calendarWidth
                    )
                }
            }
        }
    }

    @ViewBuilder
    private func addEvents(eventData: [CKEventViewData]) -> some View {
        ForEach(eventData, id: \.anyHashableID) { event in
            if calendar.isDate(event.event.startDate, inSameDayAs: date) && !event.allDay {
                CKEventView(
                    event,
                    observer: observer,
                    weekView: false
                )
            }
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

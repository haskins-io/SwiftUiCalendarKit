//
//  CKTimelineWeek.swift
//
//  Created by Mark Haskins on 09/04/2024.
//

import Combine
import SwiftUI

///
/// CKTimelineWeek
///
/// This Calendar type is used for showing a single week on a large screen size such as an iPad or Mac
///
/// - Paramters
///   - observer: Listen to this to be notified when an event is tapped/clicked
///   - events: an array of events that conform to CKEventSchema
///   - date: The date for the calendar to show
///
public struct CKTimelineWeek: View {

    @Environment(\.ckConfig)
    private var config

    @ObservedObject var observer: CKCalendarObserver

    @Binding var date: Date

    private var events: [any CKEventSchema]
    private let calendar = Calendar.current

    @State private var timelinePosition = 0.0
    @State private var time = Date()
    private let timer: Publishers.Autoconnect<Timer.TimerPublisher>

    @State private var calendarWidth: CGFloat = .zero

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

                VStack(alignment: .leading) {

                    CKCalendarHeader(currentDate: $date, addWeek: true)

                    CKWeekOfYear(date: date).padding(.leading, 10)

                    CKDayHeader(currentDate: $date, width: calendarWidth, showTime: true, showDate: true)

                    Divider()

                    timeline()
                }
            }
        }
    }

    @ViewBuilder
    private func timeline() -> some View {

        let colWidth = (calendarWidth - CGFloat(55)) / CGFloat(7)

        let eventData = CKUtils.generateEventViewData(
            date: date,
            events: events,
            width: colWidth
        )

        addAllDayEvents(eventData: eventData, width: colWidth)

        ScrollView {

            ZStack(alignment: .topLeading) {

                CKTimeline()

                ForEach(eventData, id: \.anyHashableID) { event in
                    if !event.allDay {
                        CKEventView(
                            event,
                            observer: observer,
                            weekView: true
                        )
                    }
                }

                ForEach(1..<7) { day in

                    let offset: CGFloat = colWidth * CGFloat(day)

                    Rectangle()
                        .fill(Color.gray)
                        .frame(width: 1,
                               height: 1460,
                               alignment: .center)
                        .offset(x: offset + 45, y: 10)
                }

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
    private func addAllDayEvents(eventData: [CKEventViewData], width: CGFloat) -> some View {

        VStack(spacing: 0) {
            ForEach(eventData, id: \.anyHashableID) { event in
                if event.allDay {
                    CKDayEventView(
                        event,
                        observer: observer,
                        weekView: true,
                        width: width
                    )
                }
            }
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

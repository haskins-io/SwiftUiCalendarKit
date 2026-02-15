//
//  SingleTimeline.swift
//  freya
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

    @Environment(\.ckConfig) private var config

    @ObservedObject var observer: CKCalendarObserver

    @Binding private var date: Date

    private var events: [any CKEventSchema]
    private let calendar = Calendar.current

    @State private var timelinePosition = 0.0
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

        GeometryReader { proxy in

            VStack(alignment: .leading) {

                HStack {
                    Text(date.formatted(.dateTime.day().month(.wide)))
                        .bold()
                    Text(date.formatted(.dateTime.year()))
                }
                .padding(.leading, 10)
                .padding(.top, 5)
                .font(.title)

                Text(date.formatted(.dateTime.weekday(.wide))).padding(.leading, 10)

                Divider().padding([.leading, .trailing], 10)

                dayView(width: proxy.size.width)
            }
        }
    }

    @ViewBuilder
    private func dayView(width: CGFloat) -> some View {

        ScrollView {

            ZStack(alignment: .topLeading) {

                CKTimeline()

                let eventData = CKUtils.generateEventViewData(
                    date: date,
                    events: events,
                    width: width - 55
                )

                ForEach(eventData, id: \.anyHashableID) { event in
                    if calendar.isDate(event.event.startDate, inSameDayAs: date) {
                        CKEventView(
                            event,
                            observer: observer,
                            weekView: false
                        )
                    }
                }

                if config.showTime {
                    CKTimeIndicator()
                        .offset(x: 0, y: timelinePosition)
                }
            }
            .onReceive(timer) { _ in
                guard config.showTime else {
                    return
                }
                if Calendar.current.component(.second, from: Date()) == 0 {
                    timelinePosition = CKUtils.currentTimelinePosition()
                }
            }
        }
        .defaultScrollAnchor(.center)
    }
}

#Preview {

    let event1 = CKEvent(
        startDate: Date().dateFrom(13, 2, 2026, 12, 00),
        endDate: Date().dateFrom(13, 2, 2026, 13, 00),
        text: "Event 1",
        backCol: "#D74D64"
    )

    let event2 = CKEvent(
        startDate: Date().dateFrom(14, 2, 2026, 14, 15),
        endDate: Date().dateFrom(14, 2, 2026, 14, 45),
        text: "Event 2",
        backCol: "#3E56C2"
    )

    let event3 = CKEvent(
        startDate: Date().dateFrom(15, 2, 2026, 16, 30),
        endDate: Date().dateFrom(15, 2, 2026, 17, 00),
        text: "Event 3",
        backCol: "#F6D264"
    )

    return CKTimelineDay(
        observer: CKCalendarObserver(),
        events: [event1, event2, event3],
        date: .constant(Date())
    )
}

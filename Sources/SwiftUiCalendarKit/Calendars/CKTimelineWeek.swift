//
//  CalendarWeekView.swift
//  freya
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

    @Environment(\.ckConfig) private var config

    @ObservedObject var observer: CKCalendarObserver

    @Binding var date: Date

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

                CKCalendarHeader(currentDate: $date, addWeek: true)

                CKDayHeader(currentDate: $date, width: proxy.size.width, showTime: true, showDate: true)

                Divider()

                timeline(proxy: proxy)
            }
        }
    }

    @ViewBuilder
    private func timeline(proxy: GeometryProxy) -> some View {

        ScrollView {

            ZStack(alignment: .topLeading) {

                CKTimeline()

                let eventData = CKUtils.generateEventViewData(
                    date: date,
                    events: events,
                    width: ((proxy.size.width - CGFloat(55)) / 7)
                )

                ForEach(eventData, id: \.anyHashableID) { event in
                    CKEventView(
                        event,
                        observer: observer,
                        weekView: true
                    )
                }

                ForEach(1..<7) { day in

                    let offset: CGFloat = ((proxy.size.width - CGFloat(55)) / CGFloat(7)) * CGFloat(day)

                    Rectangle()
                        .fill(Color.gray)
                        .frame(width: 1,
                               height: 1460,
                               alignment: .center)
                        .offset(x: offset + 45, y: 10)
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

    return CKTimelineWeek(
        observer: CKCalendarObserver(),
        events: [event1, event2, event3],
        date: .constant(Date())
    )
}

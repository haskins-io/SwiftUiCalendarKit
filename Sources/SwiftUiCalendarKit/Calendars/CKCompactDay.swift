//
//  File.swift
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

    @Environment(\.ckConfig) private var config

    @Binding private var currentDate: Date

    @State private var headerDay: Date = Date()

    @State private var daySlider: [Date] = []
    @State private var currentDayIndex: Int = 1
    @State private var createDay: Bool = false

    private let detail: (any CKEventSchema) -> Detail
    private var events: [any CKEventSchema]
    private let calendar = Calendar.current

    @State private var timelinePosition = 0.0
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
            .onChange(of: currentDate) { newDate in
                headerDay = newDate
                daySlider.removeAll()
                calcDaySliders(newDate: newDate)
            }
            .onChange(of: currentDayIndex) { newValue in

                // If user hits an edge, immediately paginate and reposition
                if newValue == 0 {
                    if let firstDate = daySlider.first {
                        daySlider.insert(firstDate.previousDate(), at: 0)
                        daySlider.removeLast()
                        currentDayIndex = 1
                    }
                } else if newValue == daySlider.count - 1 {
                    if let lastDate = daySlider.last {
                        daySlider.append(lastDate.nextDate())
                        daySlider.removeFirst()
                        currentDayIndex = daySlider.count - 2
                    }
                }

                // Update header/date bindings
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

            Text(headerDay.formatted(.dateTime.weekday(.wide))).padding(.leading, 10)
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

        ScrollView {

            ZStack(alignment: .topLeading) {

                CKTimeline()

                let eventData = CKUtils.generateEventViewData(
                    date: date,
                    events: events,
                    width: width - 65
                )

                ForEach(eventData, id: \.anyHashableID) { event in
                    if calendar.isDate(event.event.startDate, inSameDayAs: date) {
                        CKCompactEventView(
                            event,
                            detail: detail
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
            .padding(5)
        }
        .defaultScrollAnchor(.center)
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

        CKCompactDay(
            detail: { _ in EmptyView() },
            events: [event1, event2, event3],
            date: .constant(Date())
        )
    }
}

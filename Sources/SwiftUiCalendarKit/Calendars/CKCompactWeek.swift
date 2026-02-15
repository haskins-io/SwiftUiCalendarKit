//
//  CalendarCompactWeekView.swift
//  freya
//
//  Created by Mark Haskins on 09/04/2024.
//

import Combine
import SwiftUI

///
/// CKCompactMonth
///
/// This Calendar type is used for showing a week on a compact screen size such as an iPhone
///
/// - Paramters
///   - detail: The view that should be shown when an event in the Calendar is tapped.
///   - events: an array of events that conform to CKEventSchema
///   - date: The date for the calendar to show
///
public struct CKCompactWeek<Detail: View>: View {

    @Environment(\.ckConfig) private var config

    @Binding private var date: Date

    @State private var headerMonth: Date = Date()

    @State private var weekSlider: [[Date.WeekDay]] = []
    @State private var currentWeekIndex: Int = 1
    @State private var createWeek: Bool = false

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

        self._date = date
        self._headerMonth = State(initialValue: date.wrappedValue)

        self.timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
        _timelinePosition = State(initialValue: CKUtils.currentTimelinePosition())
    }
    public var body: some View {

        VStack {
            timelineView()
                .safeAreaInset(edge: .top, spacing: 0) {
                    headerView()
                }
        }
        .onAppear(perform: {
            calcWeekSliders(currentDate: date)
        })
        .onChange(of: date) { newDate in
            headerMonth = newDate
            weekSlider.removeAll()
            calcWeekSliders(currentDate: newDate)
        }
        .onChange(of: currentWeekIndex) { newValue in
            // do we need to create a new Week Row
            if newValue == 0 || newValue == (weekSlider.count - 1) {
                createWeek = true
            }

            // update header so Month reflects correctly
            headerMonth = weekSlider[1][0].date
            date = headerMonth
        }
    }

    /// - Timeline View
    @ViewBuilder
    private func timelineView() -> some View {

        GeometryReader { proxy in

            VStack(alignment: .leading) {

                Divider()

                ScrollView {

                    ZStack(alignment: .topLeading) {

                        CKTimeline()

                        let eventData = CKUtils.generateEventViewData(
                            date: date,
                            events: events,
                            width: proxy.size.width - 65
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
                }
                .defaultScrollAnchor(.center)
            }
        }
    }

    /// - Header View
    @ViewBuilder
    private func headerView() -> some View {

        VStack(alignment: config.headingAlignment) {

            // Date headline
            HStack {
                Text(headerMonth.formatted(.dateTime.month(.wide)))
                    .bold()
                Text(headerMonth.formatted(.dateTime.year()))
            }
            .padding(.leading, 10)
            .padding(.top, 5)
            .font(.title)

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
            .frame(height: 70)
            .padding(5)
        }
    }

    /// - Week Row
    @ViewBuilder
    private func weekRow(_ week: [Date.WeekDay]) -> some View {

        HStack(spacing: 0) {

            ForEach(week) { day in

                let status = Calendar.current.isDate(day.date, inSameDayAs: Date())

                VStack(spacing: 6) {
                    Text(day.string.prefix(3))
                    ZStack {
                        RoundedRectangle(cornerRadius: 5)
                            .fill(
                                Calendar.current.isDate(day.date, inSameDayAs: Date()) ?
                                config.currentDayColour : calendar.isDate(day.date, inSameDayAs: date) ? Color.blue.opacity(0.10) :
                                        .clear
                            )
                            .frame(width: 27, height: 27)

                        Text(day.date.toString("dd"))
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
        }
        .background {
            GeometryReader {
                let minX = $0.frame(in: .global).minX

                Color.clear
                    .preference(key: OffsetKey.self, value: minX)
                    .onPreferenceChange(OffsetKey.self) { value in
                        if value.rounded() == 5 && createWeek {
                            paginateWeek()
                            createWeek = false
                        }
                    }
            }
        }
    }

    private func paginateWeek() {
        if weekSlider.indices.contains(currentWeekIndex) {
            if let firstDate = weekSlider[currentWeekIndex].first?.date, currentWeekIndex == 0 {
                weekSlider.insert(firstDate.createPreviousWeek(), at: 0)
                weekSlider.removeLast()
                currentWeekIndex = 1
            }

            if let lastDate = weekSlider[currentWeekIndex].last?.date, currentWeekIndex == (weekSlider.count - 1) {
                weekSlider.append(lastDate.createNextWeek())
                weekSlider.removeFirst()
                currentWeekIndex = weekSlider.count - 2
            }
        }
    }

    private func calcWeekSliders(currentDate: Date) {

        if weekSlider.isEmpty {
            let currentWeek = currentDate.fetchWeek()

            if let firstDate = currentWeek.first?.date {
                weekSlider.append(firstDate.createPreviousWeek())
            }

            weekSlider.append(currentWeek)

            if let lastDate = currentWeek.last?.date {
                weekSlider.append(lastDate.createNextWeek())
            }
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

        CKCompactWeek(
            detail: { _ in EmptyView() },
            events: [event1, event2, event3],
            date: .constant(Date())
        )
    }
}

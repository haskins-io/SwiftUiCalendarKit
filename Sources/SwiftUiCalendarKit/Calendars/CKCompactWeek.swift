//
//  CKCompactWeek.swift
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

    @Environment(\.ckConfig)
    private var config

    @Binding private var date: Date

    @State private var headerMonth = Date()

    @State private var weekSlider: [[WeekDay]] = []
    @State private var currentWeekIndex: Int = 1
    @State private var createWeek: Bool = false

    @State private var calendarWidth: CGFloat = .zero

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
        .onChange(of: date, initial: false) {
            headerMonth = date
            weekSlider.removeAll()
            calcWeekSliders(currentDate: date)
        }
        .onChange(of: currentWeekIndex, initial: false) {
            // do we need to create a new Week Row
            if currentWeekIndex == 0 || currentWeekIndex == (weekSlider.count - 1) {
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

        GeometryReader { geometry in

            Color.clear
                .onChange(of: geometry.size) { _, newSize in
                    guard newSize.width > 0, newSize.height > 0 else {
                        return
                    }

                    calendarWidth = newSize.width
                }

            if calendarWidth != .zero {
                let eventData = CKUtils.generateEventViewData(
                    date: date,
                    events: events,
                    width: calendarWidth - 50
                )

                VStack(alignment: .leading, spacing: 0) {

                    Divider()

                    CKCompactDayEventsView(date: date, eventData: eventData, detail: detail)

                    ScrollView {
                        timelineEvents(eventData: eventData)
                    }
                    .defaultScrollAnchor(.center)
                }
            }
        }
    }

    @ViewBuilder
    private func timelineEvents(eventData: [CKEventViewData]) -> some View {

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
    }

    /// - Header View
    @ViewBuilder
    private func headerView() -> some View {

        VStack(alignment: config.headingAlignment) {

            HStack {
                Text(headerMonth.formatted(.dateTime.month(.wide)))
                    .bold()
                Text(headerMonth.formatted(.dateTime.year()))
            }
            .padding(.leading, 10)
            .padding(.top, 5)
            .font(.title)

            CKWeekOfYear(date: date)

            TabView(selection: $currentWeekIndex) {
                ForEach(weekSlider.indices, id: \.self) { index in
                    let week = weekSlider[index]
                    weekRow(week)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: 70)
            .padding(5)
        }
    }

    /// - Week Row
    @ViewBuilder
    private func weekRow(_ week: [WeekDay]) -> some View {

        HStack(spacing: 0) {

            ForEach(week) { day in

                let status = calendar.isDate(day.date, inSameDayAs: Date())

                VStack(spacing: 6) {

                    Text(day.string.prefix(3))

                    ZStack {
                        RoundedRectangle(cornerRadius: 5)
                            .fill(
                                calendar.isDate(day.date, inSameDayAs: Date()) ?
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
        CKCompactWeek(
            detail: { _ in EmptyView() },
            events: testEvents,
            date: .constant(Date())
        )
        .showWeekNumbers(true)
        .workingHours(start: 9, end: 17)
    }
}

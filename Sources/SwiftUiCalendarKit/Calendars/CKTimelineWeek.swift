//
//  CKTimelineWeek.swift
//
//  Created by Mark Haskins on 09/04/2024.
//

import Combine
import SwiftUI

/// `CKTimelineWeek` can be used for showing a single day calendar on a compact screen size such as an iPhone.
///
///     CKTimelineWeek(
///         observer: CKCalendarObserver(),
///         events: events,
///         date: $date
///     )
///
/// - Parameter observer: Listen to this to be notified when an event is tapped/clicked
/// - Parameter events: an array of events that conform to ``CKEventSchema``.
/// - Parameter date: The date for the calendar to show.

public struct CKTimelineWeek: View {

    @Environment(\.ckConfig)
    private var config

    @ObservedObject private var observer: CKCalendarObserver

    @Binding private var calendarDate: Date

    @State private var columnWidth: CGFloat = .zero

    @State private var timelinePosition = 0.0
    @State private var time = Date()

    private var events: [any CKEventSchema]

    private let timer: Publishers.Autoconnect<Timer.TimerPublisher>

    private var calendar = Calendar.current

    private var timebarWidth: CGFloat = 40
    public init(
        observer: CKCalendarObserver,
        events: [any CKEventSchema],
        date: Binding<Date>
    ) {
        self._observer = .init(wrappedValue: observer)
        self.events = events
        self._calendarDate = date

        self.timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
        _timelinePosition = State(initialValue: CKUtils.currentTimelinePosition())
    }

    public var body: some View {

        let eventData = CKUtils.generateEventViewData(
            date: calendarDate,
            events: events,
            width: columnWidth
        )

        let week = calendarDate.fetchWeek()

        GeometryReader { geometry in

            Color.clear
                .onChange(of: geometry.size) { _, newSize in
                    guard newSize.width > 0, newSize.height > 0 else {
                        return
                    }

                    // Account for 6 gaps of 1pt between 7 columns
                    columnWidth = (((geometry.size.width - timebarWidth) - 6) / 7)
                }

            if columnWidth != .zero {

                VStack(spacing: 0) {

                    CKCalendarHeader(currentDate: $calendarDate, addWeek: true)

                    CKWeekOfYear(date: calendarDate).padding(.leading, 10)

                    Grid(horizontalSpacing: 1, verticalSpacing: 0) {
                        GridRow(alignment: .top) {
                            calendarHeader(week: week)
                        }
                        Divider()
                        GridRow(alignment: .top) {
                            multiDays(eventData: eventData, week: week)
                        }
                        Divider()
                        GridRow(alignment: .top) {
                            allDay(eventData: eventData, week: week)
                        }
                    }

                    Divider().frame(height: 2).overlay(.black)

                    ScrollView {
                        Grid(horizontalSpacing: 1) {
                            GridRow {
                                showTimes()

                                ForEach(week) { weekDay in
                                    dayView(
                                        events: eventData,
                                        date: weekDay.date
                                    )
                                }
                            }
                        }
                    }
                    .defaultScrollAnchor(.center)
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
        }
    }

    @ViewBuilder
    private func calendarHeader(week: [WeekDay]) -> some View {

        Color.clear
            .gridCellUnsizedAxes([.horizontal, .vertical])
            .frame(minWidth: timebarWidth + 5, idealWidth: timebarWidth + 5, maxWidth: timebarWidth + 5)

        ForEach(week, id: \.id) { weekDay in

            VStack(alignment: .center, spacing: 0) {
                Text(weekDay.string.prefix(3))
                ZStack {
                    RoundedRectangle(cornerRadius: 5)
                        .fill(Calendar.current.isDate(weekDay.date, inSameDayAs: Date()) ? Color.blue.opacity(0.10) : Color.clear)
                        .frame(width: 27, height: 27)

                    Text(weekDay.date.toString("dd"))
                }
            }
            .frame(minWidth: columnWidth, idealWidth: columnWidth, maxWidth: columnWidth)
            .modifier(GridOverlayModifier())
        }
    }

    @ViewBuilder
    private func multiDays(eventData: [CKEventViewData], week: [WeekDay]) -> some View {

        Color.clear
            .gridCellUnsizedAxes([.horizontal, .vertical])
            .frame(minWidth: timebarWidth, idealWidth: timebarWidth, maxWidth: timebarWidth)

        ForEach(week) { weekDay in
            addMultiDayEvents(
                eventData: eventData,
                date: weekDay.date
            )
        }
    }

    @ViewBuilder
    private func allDay(eventData: [CKEventViewData], week: [WeekDay]) -> some View {

        Color.clear
            .gridCellUnsizedAxes([.horizontal, .vertical])
            .frame(minWidth: timebarWidth, idealWidth: timebarWidth, maxWidth: timebarWidth)

        ForEach(week) { weekDay in
            addAllDayEvents(
                eventData: eventData,
                date: weekDay.date
            )
        }
    }

    @ViewBuilder
    private func addMultiDayEvents(eventData: [CKEventViewData], date: Date) -> some View {

        if doesDateHaveAnyMultiDayEvents(eventData: eventData, date: date) {

            VStack(spacing: 0) {

                ForEach(eventData, id: \.anyHashableID) { eventData in

                    if isMultiDayEvent(event: eventData.event) {

                        if calendar.isDate(eventData.event.startDate, inSameDayAs: date) {
                            singleDayEventView(eventData: eventData)
                        } else {
                            if CKUtils.doesEventOccurOnDate(event: eventData.event, date: date) {
                                multiDayFillerView(eventData: eventData)
                            }
                        }
                    }
                }
            }
            .frame(minWidth: columnWidth, idealWidth: columnWidth, maxWidth: columnWidth)
            .modifier(GridOverlayModifier())
            .padding(.top, 5)
        } else {
            Color.clear
                .gridCellUnsizedAxes([.horizontal, .vertical])
                .frame(minWidth: columnWidth, idealWidth: columnWidth, maxWidth: columnWidth)
                .modifier(GridOverlayModifier())
        }
    }

    @ViewBuilder
    private func addAllDayEvents(eventData: [CKEventViewData], date: Date) -> some View {

        if doesDateHaveAnyAllDayEvents(eventData: eventData, date: date) {

            VStack(spacing: 0) {

                ForEach(eventData, id: \.anyHashableID) { eventData in

                    if isSingleDayEvent(event: eventData.event, date: date) {
                        singleDayEventView(eventData: eventData)
                    }
                }
            }
            .frame(minWidth: columnWidth, idealWidth: columnWidth, maxWidth: columnWidth)
            .overlay(
                Rectangle()
                    .frame(width: 1, height: nil, alignment: .trailing)
                    .foregroundColor(Color.gray), alignment: .trailing)
            .padding(.top, 5)
        } else {
            Color.clear
                .gridCellUnsizedAxes([.horizontal, .vertical])
                .frame(minWidth: columnWidth, idealWidth: columnWidth, maxWidth: columnWidth)
                .modifier(GridOverlayModifier())
        }
    }

    @ViewBuilder
    private func singleDayEventView(eventData: CKEventViewData) -> some View {

        VStack(alignment: .center) {
            Text(CKUtils.eventText(event: eventData.event)).bold().padding(.leading, 5)
        }
        .foregroundColor(.primary)
        .font(.caption)
        .frame(minWidth: columnWidth - 15, idealWidth: columnWidth - 15, maxWidth: columnWidth - 15)
        .padding(6)
        .background(.thinMaterial)
        .background(
            RoundedRectangle(cornerRadius: 3)
                .fill(eventData.event.backgroundAsColor())
                .opacity(0.5)
                .shadow(radius: 5, x: 2, y: 5)
        )
        .overlay {
            HStack {
                Rectangle()
                    .fill(eventData.event.backgroundAsColor())
                    .frame(maxHeight: .infinity, alignment: .leading)
                    .frame(width: 4)
                Spacer()
            }
        }
    }

    @ViewBuilder
    private func multiDayFillerView(eventData: CKEventViewData) -> some View {

        VStack(alignment: .leading, spacing: 0) {
            Text("")
        }
        .frame(minWidth: columnWidth - 15, idealWidth: columnWidth - 15, maxWidth: columnWidth - 15)
        .padding(6)
        .background(.thinMaterial)
        .background(
            RoundedRectangle(cornerRadius: 3)
                .fill(eventData.event.backgroundAsColor())
                .opacity(0.5)
                .shadow(radius: 5, x: 2, y: 5)
        )
    }

    @ViewBuilder
    private func showTimes() -> some View {

        VStack(alignment: .leading, spacing: 0) {
            ForEach(0..<24) { hour in
                HStack {
                    Text(String(format: "%02d:00", hour))
                        .font(.caption)
                        .frame(width: timebarWidth, alignment: .trailing)
                }
                .padding(.trailing, 5)
                .frame(height: CKTimeline.hourHeight)
            }
        }
        .padding(0)
    }

    @ViewBuilder
    private func dayView(events: [CKEventViewData], date: Date) -> some View {

        ZStack(alignment: .topLeading) {
            CKTimeline(showTime: false)
                .frame(minWidth: columnWidth , idealWidth: columnWidth, maxWidth: columnWidth)

            if config.showTime {
                CKTimeIndicator(date: date, time: time, showTime: false)
                    .offset(x: 0, y: timelinePosition)
            }

            addEvents(eventData: events, date: date)
        }
    }

    @ViewBuilder
    private func addEvents(eventData: [CKEventViewData], date: Date) -> some View {

        ForEach(eventData, id: \.anyHashableID) { event in
            if calendar.isDate(event.event.startDate, inSameDayAs: date) && !event.allDay {
                CKTimelineWeekEventView(
                    event,
                    observer: observer
                )
            }
        }
    }
}

extension CKTimelineWeek {
    private func doesDateHaveAnyMultiDayEvents(eventData: [CKEventViewData], date: Date) -> Bool {

        var hasEvents = false

        for event in eventData where (isMultiDayEvent(event: event.event) &&
                                      CKUtils.doesEventOccurOnDate(event: event.event, date: date)) {
            hasEvents = true
            break
        }

        return hasEvents
    }

    private func isSingleDayEvent(event: any CKEventSchema, date: Date) -> Bool {

        guard event.isAllDay else {
            return false
        }

        guard calendar.isDate(event.startDate, inSameDayAs: date) else {
            return false
        }

        guard !isMultiDayEvent(event: event) else {
            return false
        }

        return true
    }

    private func isMultiDayEvent(event: any CKEventSchema) -> Bool {

        guard event.isAllDay else {
            return false
        }

        // is start and end in same day
        guard !calendar.isDate(event.startDate, inSameDayAs: event.endDate) else {
            return false
        }

        return true
    }

    private func doesDateHaveAnyAllDayEvents(eventData: [CKEventViewData], date: Date) -> Bool {

        var hasEvents = false

        for event in eventData where isSingleDayEvent(event: event.event, date: date) {
            hasEvents = true
            break
        }

        return hasEvents
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

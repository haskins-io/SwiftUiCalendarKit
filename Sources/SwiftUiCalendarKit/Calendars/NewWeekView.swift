//
//  SwiftUIView.swift
//  SwiftUiCalendarKit
//
//  Created by Mark Haskins on 18/02/2026.
//

import SwiftUI

public struct NewWeekView: View {

    @ObservedObject var observer: CKCalendarObserver
    var events: [any CKEventSchema]
    @Binding var calendarDate: Date

    public init(
        observer: CKCalendarObserver,
        events: [any CKEventSchema],
        date: Binding<Date>
    ) {
        self._observer = .init(wrappedValue: observer)
        self.events = events
        self._calendarDate = date
    }

    public var body: some View {
        GeometryReader { proxy in
            VStack {
                CKCalendarHeader(currentDate: $calendarDate, addWeek: true)

                CKWeekOfYear(date: calendarDate)
                    .padding(.leading, 10)

                let eventData = CKUtils.generateEventViewData(
                    date: calendarDate,
                    events: events,
                    width: (proxy.size.width / 7) - 10
                )

                let week = calendarDate.fetchWeek()

                Grid(horizontalSpacing: 0) {
                    GridRow(alignment: .top) {
                        Color.clear
                            .gridCellUnsizedAxes([.horizontal, .vertical])
                            .frame(width: 40)

                            ForEach(Array(week.enumerated()), id: \.offset) { index, weekDay in

                                VStack(alignment: .center, spacing: 0) {
                                    Text(weekDay.string.prefix(3))
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 5)
                                            .fill(Calendar.current.isDate(weekDay.date, inSameDayAs: Date()) ? Color.blue.opacity(0.10) : Color.clear)
                                            .frame(width: 27, height: 27)

                                        Text(weekDay.date.toString("dd"))
                                    }
                                }
                                .frame(width: (proxy.size.width / 7) - 10)
                            }
                    }
                }

                Grid(horizontalSpacing: 0) {
                    GridRow(alignment: .top) {
                        Color.clear
                            .gridCellUnsizedAxes([.horizontal, .vertical])
                            .frame(width: 40)
                        ForEach(week) { weekDay in
                            addMultiDayEvents(
                                eventData: eventData,
                                date: weekDay.date,
                                width: (proxy.size.width / 7) - 10
                            )
                        }
                    }
                }

                Grid(horizontalSpacing: 0) {
                    GridRow(alignment: .top) {
                        Color.clear
                            .gridCellUnsizedAxes([.horizontal, .vertical])
                            .frame(width: 40)
                        ForEach(week) { weekDay in
                            addAllDayEvents(
                                eventData: eventData,
                                date: weekDay.date,
                                width: (proxy.size.width / 7) - 10
                            )
                        }
                    }
                }
                .padding(.bottom, 1)

                ScrollView {
                    Grid(horizontalSpacing: 1) {
                        GridRow {
                            showTimes()
                            ForEach(week) { weekDay in
                                dayView(
                                    events: eventData,
                                    date: weekDay.date,
                                    width: (proxy.size.width - CGFloat(35)) / CGFloat(7)
                                )
                            }
                        }
                    }
                }
                .defaultScrollAnchor(.center)
            }
        }
    }

    @ViewBuilder
    private func addMultiDayEvents(eventData: [CKEventViewData], date: Date, width: CGFloat) -> some View {
        if doesDateHaveAnyMultiDayEvents(eventData: eventData, date: date) {
            VStack {
                ForEach(eventData, id: \.anyHashableID) { eventData in
                    if isMultiDayEvent(event: eventData.event) {
                        if calendar.isDate(eventData.event.startDate, inSameDayAs: date) {
                            singleDayEventView(eventData: eventData, width: width)
                        } else {
                            let start = calendar.date(byAdding: .day, value: 1, to: eventData.event.startDate)?.midnight ?? eventData.event.startDate.midnight
                            let dayAfter = calendar.date(byAdding: .day, value: 1, to: eventData.event.endDate)?.midnight ?? eventData.event.endDate.midnight
                            let end = calendar.date(byAdding: .minute, value: -1, to: dayAfter) ?? dayAfter

                            let eventRange = start...end
                            if eventRange.contains(date) {
                                multiDayFillerView(eventData: eventData, width: width)
                            }
                        }
                    }
                }
            }
            .padding(0)
        } else {
            Color.clear
                .gridCellUnsizedAxes([.horizontal, .vertical])
                .frame(width: width)
        }
    }

    @ViewBuilder
    private func addAllDayEvents(eventData: [CKEventViewData], date: Date, width: CGFloat) -> some View {

        if doesDateHaveAnyAllDayEvents(eventData: eventData, date: date) {
            VStack(spacing: 0) {
                ForEach(eventData, id: \.anyHashableID) { eventData in
                    if isSingleDayEvent(event: eventData.event, date: date) {
                        singleDayEventView(eventData: eventData, width: width)
                    }
                }
            }
            .padding(0)
        } else {
            Color.clear
                .gridCellUnsizedAxes([.horizontal, .vertical])
                .frame(width: width)
        }
    }

    private func doesDateHaveAnyAllDayEvents(eventData: [CKEventViewData], date: Date) -> Bool {

        var hasEvents = false

        for event in eventData {
            if isSingleDayEvent(event: event.event, date: date) {
                hasEvents = true
                break
            }
        }

        return hasEvents
    }

    private func doesDateHaveAnyMultiDayEvents(eventData: [CKEventViewData], date: Date) -> Bool {

        var hasEvents = false

        for event in eventData {
            if isMultiDayEvent(event: event.event) {

                let start = event.event.startDate.midnight
                let dayAfter = calendar.date(byAdding: .day, value: 1, to: event.event.endDate)?.midnight ?? event.event.endDate.midnight
                let end = calendar.date(byAdding: .minute, value: -1, to: dayAfter) ?? dayAfter

                let eventRange = start...end
                if eventRange.contains(date) {
                    hasEvents = true
                    break
                }
            }
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

    @ViewBuilder
    private func singleDayEventView(eventData: CKEventViewData, width: CGFloat) -> some View {
        VStack(alignment: .leading) {
            Text(eventData.event.text).bold().padding(.leading, 5)
        }
        .foregroundColor(.primary)
        .font(.caption)
        .frame(maxWidth: width - 5, alignment: .leading)
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
    private func multiDayFillerView(eventData: CKEventViewData, width: CGFloat) -> some View {
        VStack(alignment: .leading) {
            Text("")
        }
        .frame(maxWidth: width - 5)
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
                        .frame(width: 40, alignment: .trailing)
                }
                .padding(.trailing, 5)
                .frame(height: CKTimeline.hourHeight)
            }
        }
    }

    @ViewBuilder
    private func dayView(events: [CKEventViewData], date: Date, width: CGFloat) -> some View {

        ZStack(alignment: .topLeading) {
            CKTimeline(showTime: false)
            addEvents(eventData: events, date: date)
        }
    }

    @ViewBuilder
    private func addEvents(eventData: [CKEventViewData], date: Date) -> some View {
        ForEach(eventData, id: \.anyHashableID) { event in
            if calendar.isDate(event.event.startDate, inSameDayAs: date) && !event.allDay {
                NewWeekEventView(
                    event,
                    observer: observer
                )
            }
        }
    }
}

#Preview {
    NewWeekView(
        observer: CKCalendarObserver(),
        events:testEvents,
        date: .constant(Date())
    )
    .workingHours(start: 9, end: 17)
}

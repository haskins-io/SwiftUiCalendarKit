//
//  CalendarCompactWeekView.swift
//  freya
//
//  Created by Mark Haskins on 09/04/2024.
//

import SwiftUI

public struct CKCompactWeek<Detail: View>: View {

    @Binding private var date: Date

    @State private var headerMonth: Date = Date()

    @State private var weekSlider: [[Date.WeekDay]] = []
    @State private var currentWeekIndex: Int = 1
    @State private var createWeek: Bool = false

    private let detail: (any CKEventSchema) -> Detail
    private var events: [any CKEventSchema]
    private let calendar = Calendar.current

    public init(
        @ViewBuilder detail: @escaping (any CKEventSchema) -> Detail,
        events: [any CKEventSchema],
        date: Binding<Date>
    ) {
        self.detail = detail
        self.events = events

        self._date = date
        self._headerMonth = State(initialValue: date.wrappedValue)
    }
    public var body: some View {

        VStack {
            timelineView()
                .safeAreaInset(edge: .top, spacing: 0) {
                    headerView()
                }
        }
        .onAppear(perform: {
            if weekSlider.isEmpty {
                let currentWeek = Date().fetchWeek()

                if let firstDate = currentWeek.first?.date {
                    weekSlider.append(firstDate.createPreviousWeek())
                }

                weekSlider.append(currentWeek)

                if let lastDate = currentWeek.last?.date {
                    weekSlider.append(lastDate.createNextWeek())
                }
            }
        })
        .onChange(of: currentWeekIndex) { newValue in
            // do we need to create a new Week Row
            if newValue == 0 || newValue == (weekSlider.count - 1) {
                createWeek = true
            }

            // update header so Month reflects correctly
            headerMonth = weekSlider[1][0].date
        }
    }

    /// - Timeline View
    @ViewBuilder
    func timelineView() -> some View {

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
                    }
                }
            }
        }
    }

    /// - Header View
    @ViewBuilder
    func headerView() -> some View {

        VStack(alignment: .leading) {

            // Date headline
            HStack {
                Text(headerMonth.formatted(.dateTime.month(.wide)))
                    .bold()
                Text(headerMonth.formatted(.dateTime.year()))
            }
            .padding(.leading, 10)
            .padding(.top, 5)
            .font(.title)
            
            TabView(selection: $currentWeekIndex){
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
    func weekRow(_ week: [Date.WeekDay]) -> some View {

        HStack(spacing: 0) {
        
            ForEach(week) { day in

                let status = Calendar.current.isDate(day.date, inSameDayAs: Date())

                VStack(spacing: 6) {
                    Text(day.string.prefix(3))
                    ZStack {
                        RoundedRectangle(cornerRadius: 5)
                            .fill(
                                Calendar.current.isDate(day.date, inSameDayAs: Date()) ?
                                Color.red : calendar.isDate(day.date, inSameDayAs: date) ? Color.blue.opacity(0.10) :
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

    func paginateWeek() {
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
}

#Preview {
    NavigationView {

        let event1 = CKEvent(
            startDate: Date().dateFrom(16, 4, 2024, 12, 00),
            endDate: Date().dateFrom(16, 4, 2024, 13, 00),
            text: "Event 1",
            backCol: "#D74D64"
        )

        let event2 = CKEvent(
            startDate: Date().dateFrom(16, 4, 2024, 12, 15),
            endDate: Date().dateFrom(16, 4, 2024, 13, 15),
            text: "Event 2",
            backCol: "#3E56C2"
        )

        let event3 = CKEvent(
            startDate: Date().dateFrom(16, 4, 2024, 12, 30),
            endDate: Date().dateFrom(16, 4, 2024, 15, 01),
            text: "Event 3",
            backCol: "#F6D264"
        )

        CKCompactWeek(
            detail: { event in EmptyView() } ,
            events: [event1, event2, event3],
            date: .constant(Date().dateFrom(16, 4, 2024))
        )
    }
}

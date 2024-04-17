//
//  CalendarCompactWeekView.swift
//  freya
//
//  Created by Mark Haskins on 09/04/2024.
//

import SwiftUI

public struct CKCompactWeek<Detail: View>: View {

    @Binding private var date: Date

    private let detail: (any CKEventSchema) -> Detail

    private var events: [any CKEventSchema]

    private let calendar = Calendar(identifier: .gregorian)

    public init(
        @ViewBuilder detail: @escaping (any CKEventSchema) -> Detail,
        events: [any CKEventSchema],
        date: Binding<Date>
    ) {
        self.detail = detail
        self.events = events
        self._date = date
    }
    public var body: some View {

        VStack {
            timelineView()
                .modifier(CKSwipeModifier(date: $date, component: .day))
                .safeAreaInset(edge: .top, spacing: 0) {
                    headerView()
                        .modifier(CKSwipeModifier(date: $date, component: .weekOfYear))
                }
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
                Text(date.formatted(.dateTime.month(.wide)))
                    .bold()
                Text(date.formatted(.dateTime.year()))
            }
            .padding(.leading, 10)
            .padding(.top, 5)
            .font(.title)

            /// - Current Week row
            weekRow().padding([.leading, .trailing], 10)
        }

        .background {
            VStack(spacing: 0) {
                Color.white
                Rectangle()
                    .fill(.linearGradient(colors: [
                        .white,
                        .clear
                    ], startPoint: .top, endPoint: .bottom))
                    .frame(height: 20)
            }
            .ignoresSafeArea()
        }
    }

    /// - Week Row
    @ViewBuilder
    func weekRow() -> some View {

        HStack(spacing: 0) {
        
            ForEach(calendar.currentWeek(today: date)) { weekDay in

                let status = Calendar.current.isDate(weekDay.date, inSameDayAs: Date())

                VStack(spacing: 6) {
                    Text(weekDay.string.prefix(3))
                    ZStack {
                        RoundedRectangle(cornerRadius: 5)
                            .fill(
                                Calendar.current.isDate(weekDay.date, inSameDayAs: Date()) ?
                                Color.red : calendar.isDate(weekDay.date, inSameDayAs: date) ? Color.blue.opacity(0.10) :
                                        .clear
                            )
                            .frame(width: 27, height: 27)

                        Text(weekDay.date.toString("dd"))
                            .foregroundColor(status ? Color.white : .primary)

                    }
                }
                .hAlign(.center)
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        date = weekDay.date
                    }
                }
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, -15)
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

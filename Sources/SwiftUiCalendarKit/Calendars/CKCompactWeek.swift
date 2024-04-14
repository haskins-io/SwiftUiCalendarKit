//
//  CalendarCompactWeekView.swift
//  freya
//
//  Created by Mark Haskins on 09/04/2024.
//

import SwiftData
import SwiftUI

public struct CKCompactWeek: View {

    @ObservedObject var observer: CKCalendarObserver

    @Binding private var date: Date

    private var events: [any CKEventSchema]

    private let calendar = Calendar(identifier: .gregorian)

    public init(observer: CKCalendarObserver, events: [any CKEventSchema], date: Binding<Date>) {
        self._observer = .init(wrappedValue: observer)
        self.events = events
        self._date = date
    }
    public var body: some View {

        timelineView()
        .safeAreaInset(edge: .top, spacing: 0) {
            headerView()
        }
    }

    /// - Timeline View
    @ViewBuilder
    func timelineView() -> some View {

        GeometryReader { proxy in

            VStack(alignment: .leading) {

                ScrollView {
                    
                    ZStack(alignment: .topLeading) {

                        CKTimeline()

                        let eventData = CKUtils.generateEventViewData(
                            date: date,
                            events: events,
                            width: proxy.size.width - 65
                        )

                        ForEach(eventData, id: \.self) { event in
                            CKEventView(
                                event,
                                observer: observer,
                                applyXOffset: false
                            )
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

                let status = Calendar.current.isDate(weekDay.date, inSameDayAs: date)

                VStack(spacing: 6) {
                    Text(weekDay.string.prefix(3))
                    Text(weekDay.date.toString("dd"))
                }
                .foregroundColor(status ? Color.blue : .gray)
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
    CKCompactWeek(
        observer: CKCalendarObserver(),
        events: [
            CKEvent(startDate: Date().dateFrom(14, 4, 2024, 12, 00), endDate: Date().dateFrom(14, 4, 2024, 13, 00), text: "Date 1"),
            CKEvent(startDate: Date().dateFrom(14, 4, 2024, 12, 30), endDate: Date().dateFrom(14, 4, 2024, 13, 30), text: "Date 2"),
            CKEvent(startDate: Date().dateFrom(14, 4, 2024, 15, 00), endDate: Date().dateFrom(14, 4, 2024, 16, 00), text: "Date 3"),
        ],
        date: .constant(Date().dateFrom(14, 4, 2024))
    )
}

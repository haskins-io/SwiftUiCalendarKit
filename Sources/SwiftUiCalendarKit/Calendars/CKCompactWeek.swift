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

                        ForEach(events, id: \.anyHashableID) { event in
                            if calendar.isDate(event.startDate, inSameDayAs: date) {

                                let overlapping = CKUtils.overLappingEventsCount(event, events)

                                CKEventCell(
                                    event,
                                    overLapping: overlapping,
                                    observer: observer,
                                    width: (proxy.size.width - 70),
                                    applyXOffset: false
                                )
                            }
                        }
                    }
                }
            }
        }
    }

    private func eventCell(_ event: any CKEventSchema, width: CGFloat) -> some View {

        let duration = event.endDate.timeIntervalSince(event.startDate)
        let height = duration / 60 / 60 * CKTimeline.hourHeight

        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: event.startDate)
        let minute = calendar.component(.minute, from: event.startDate)
        let offset = (Double(hour) * (CKTimeline.hourHeight)) + Double(minute)

        return VStack(alignment: .leading) {
            Text(event.startDate.formatted(.dateTime.hour().minute()))
            Text(event.text).bold()
        }
        .font(.caption)
        .frame(maxWidth: width - 70, alignment: .leading)
        .padding(4)
        .frame(height: height, alignment: .top)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(.teal).opacity(0.5)
        )
        .padding(.trailing, 30)
        .offset(x: 50, y: offset + 30)
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
            CKEvent(startDate: Date().dateFrom(13, 4, 2024, 12, 00), endDate: Date().dateFrom(13, 4, 2024, 13, 00), text: "Date 1"),
            CKEvent(startDate: Date().dateFrom(14, 4, 2024, 12, 30), endDate: Date().dateFrom(14, 4, 2024, 13, 30), text: "Date 2"),
            CKEvent(startDate: Date().dateFrom(15, 4, 2024, 15, 00), endDate: Date().dateFrom(15, 4, 2024, 16, 00), text: "Date 3"),
        ],
        date: .constant(Date().dateFrom(13, 4, 2024))
    )
}

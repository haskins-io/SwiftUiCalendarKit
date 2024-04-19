//
//  File.swift
//  
//
//  Created by Mark Haskins on 15/04/2024.
//

import SwiftUI

public struct CKCompactDay<Detail: View>: View {

    @Binding private var currentDate: Date

    @State private var headerMonth: Date = Date()

    @State private var daySlider: [Date] = []
    @State private var currentDayIndex: Int = 1
    @State private var createDay: Bool = false

    private let detail: (any CKEventSchema) -> Detail
    private var events: [any CKEventSchema]
    private let calendar = Calendar.current

    public init(
        @ViewBuilder detail: @escaping (any CKEventSchema) -> Detail,
        events: [any CKEventSchema],
        date: Binding<Date>)
    {
        self.detail = detail
        self.events = events
        self._currentDate = date

        self._headerMonth = State(initialValue: date.wrappedValue)
    }

    public var body: some View {

        GeometryReader { proxy in

            VStack(alignment: .leading) {

                header()

                Divider().padding([.leading, .trailing], 10)

                timeline(width: proxy.size.width - 55)

            }
            .onAppear(perform: {
                if daySlider.isEmpty {
                    daySlider.append(Date().previousDate())
                    daySlider.append(Date())
                    daySlider.append(Date().nextDate())
                }
            })
            .onChange(of: currentDayIndex) { newValue in
                // do we need to create a new Week Row
                if newValue == 0 || newValue == (daySlider.count - 1) {
                    createDay = true
                }

                // update header
                headerMonth = daySlider[1]
            }
        }
    }

    @ViewBuilder
    func header() -> some View {
        HStack {
            Text(headerMonth.formatted(.dateTime.day().month(.wide)))
                .bold()
            Text(headerMonth.formatted(.dateTime.year()))
        }
        .padding(.leading, 10)
        .padding(.top, 5)
        .font(.title)

        Text(headerMonth.formatted(.dateTime.weekday(.wide))).padding(.leading, 10)
    }

    @ViewBuilder
    func timeline(width: CGFloat) -> some View {

        TabView(selection: $currentDayIndex){
            ForEach(daySlider.indices, id: \.self) { index in
                let day = daySlider[index]
                dayView(day, width)
                    .tag(index)
            }
        }
#if !os(macOS)
        .tabViewStyle(.page(indexDisplayMode: .never))
#endif
    }

    @ViewBuilder
    func dayView(_ date: Date, _ width: CGFloat) -> some View {

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
            }
            .padding(5)
        }
        .background {
            GeometryReader {
                let minX = $0.frame(in: .global).minX

                Color.clear
                    .preference(key: OffsetKey.self, value: minX)
                    .onPreferenceChange(OffsetKey.self) { value in
                        if value.rounded() == 0 && createDay {
                            paginateDay()
                            createDay = false
                        }
                    }
            }
        }
    }

    func paginateDay() {

        if daySlider.indices.contains(currentDayIndex) {
            if let firstDate = daySlider.first, currentDayIndex == 0 {
                daySlider.insert(firstDate.previousDate(), at: 0)
                daySlider.removeLast()
                currentDayIndex = 1
            }

            if let lastDate = daySlider.last, currentDayIndex == (daySlider.count - 1) {
                daySlider.append(lastDate.nextDate())
                daySlider.removeFirst()
                currentDayIndex = daySlider.count - 2
            }
        }
    }
}

#Preview {

    NavigationView {

        let event1 = CKEvent(
            startDate: Date().dateFrom(13, 4, 2024, 12, 00),
            endDate: Date().dateFrom(13, 4, 2024, 13, 00),
            text: "Event 1",
            backCol: "#D74D64"
        )

        let event2 = CKEvent(
            startDate: Date().dateFrom(13, 4, 2024, 12, 15),
            endDate: Date().dateFrom(13, 4, 2024, 13, 15),
            text: "Event 2",
            backCol: "#3E56C2"
        )

        let event3 = CKEvent(
            startDate: Date().dateFrom(13, 4, 2024, 12, 30),
            endDate: Date().dateFrom(13, 4, 2024, 15, 01),
            text: "Event 3",
            backCol: "#F6D264"
        )

        CKCompactDay(
            detail: { event in EmptyView() },
            events: [event1, event2, event3],
            date: .constant(Date().dateFrom(19, 4, 2024))
        )
    }
}


//
//  MonthDayCell.swift
//  Freya
//
//  Created by Mark Haskins on 11/04/2024.
//

import SwiftUI

struct CKMonthDayCellModifier: ViewModifier {

    func body(content: Content) -> some View {
        content
            .overlay(Rectangle().frame(width: 1, height: nil, alignment: .trailing)
                .foregroundColor(Color.gray), alignment: .trailing)
            .overlay(Rectangle().frame(width: nil, height: 1, alignment: .bottom)
                .foregroundColor(Color.gray), alignment: .bottom)
    }
}

struct CKMonthDayCell: View {

    @ObservedObject var observer: CKCalendarObserver

    let calendar = Calendar(identifier: .gregorian)

    private var date: Date
    private var month: Date

    var events: [any CKEventSchema]

    private var cellWidth: CGFloat
    private var cellHeight: CGFloat

    init(
        date: Date,
        observer: CKCalendarObserver,
        events: [any CKEventSchema],
        month: Date,
        width: CGFloat,
        height: CGFloat
    ) {

        self._observer = .init(wrappedValue: observer)

        self.date = date
        self.month = month
        
        self.events = events

        cellWidth = width
        cellHeight = height
    }

    var body: some View {

        let thisMonth = calendar.isDate(date, equalTo: month, toGranularity: .month)

        ZStack(alignment: .topLeading) {
            VStack {
                ZStack {
                    if calendar.isDateInToday(date) {
                        RoundedRectangle(cornerRadius: 5)
                            .fill(Color.red)
                            .frame(width: 27, height: 27)
                            .offset(x: (cellWidth / 2) - 17, y: ((cellHeight / 2) - 20) * -1)
                    }

                    Text(formatDate())
                        .padding(.trailing, 15)
                        .foregroundColor(calendar.isDateInToday(date) ? .white : thisMonth ? Color.primary : Color.gray)
                        .offset(x: (cellWidth / 2) - 10, y: ((cellHeight / 2) - 20) * -1)
                }

            }
            .frame(width: cellWidth, height: cellHeight)
            .modifier(CKMonthDayCellModifier())
            addEvents()
        }
    }

    @ViewBuilder
    private func addEvents() -> some View {

        ZStack {
            if events.count == 1 {
                event(event: events[0], yOffset: 36)
            }

            if events.count == 2 {
                event(event: events[0], yOffset: 36)
                event(event: events[1], yOffset: 55)
            }

            if events.count == 3 {
                event(event: events[0], yOffset: 36)
                event(event: events[1], yOffset: 52)
                event(event: events[2], yOffset: 68)
            }
        }.padding(0)
    }

    @ViewBuilder
    private func event(event: any CKEventSchema, yOffset: CGFloat) -> some View {
        HStack{
            Circle()
                .fill(event.backgroundAsColor())
                .frame(width: 10, height: 10)
            Text(event.text)
            Spacer()
            Text(event.startDate.formatted(.dateTime.hour().minute()))
        }
        .font(.caption)
        .frame(maxWidth: cellWidth, alignment: .leading)
        .padding(4)
        .frame(height: 20, alignment: .center)
        .offset(x: 0, y: yOffset)
        .onTapGesture {
            observer.eventSelected = true
            observer.event = event
        }
    }

    private func formatDate() -> String {

        if date.toString("d") == "1" {
            return date.toString("d MMM")
        } else {
            return date.toString("d")
        }
    }
}

#Preview {

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

    return CKMonthDayCell(
        date: Date(),
        observer: CKCalendarObserver(),
        events: [event1, event2, event3],
        month: Date(),
        width: 150,
        height: 150
    )
}

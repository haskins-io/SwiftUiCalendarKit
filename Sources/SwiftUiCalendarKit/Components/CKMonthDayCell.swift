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
                .foregroundColor(Color.gray.opacity(0.5)), alignment: .trailing)
            .overlay(Rectangle().frame(width: nil, height: 1, alignment: .bottom)
                .foregroundColor(Color.gray.opacity(0.5)), alignment: .bottom)
    }
}

struct CKMonthDayCell: View {

    @ObservedObject var observer: CKCalendarObserver

    let calendar = Calendar.current

    private var date: Date
    private var month: Date
    private var showTime: Bool

    var events: [any CKEventSchema]

    private var cellWidth: CGFloat
    private var cellHeight: CGFloat

    init(
        date: Date,
        observer: CKCalendarObserver,
        events: [any CKEventSchema],
        month: Date,
        width: CGFloat,
        height: CGFloat,
        showTime: Bool = false
    ) {

        self._observer = .init(wrappedValue: observer)

        self.date = date
        self.month = month
        self.showTime = showTime

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
                            .frame(width: 25, height: 25)
                            .offset(x: (cellWidth / 2) - 20, y: ((cellHeight / 2) - 15) * -1)
                    }

                    if isFirstDayOfMonth() {
                        Text(formatDate())
                            .padding(.trailing, 55)
                            .foregroundColor(calendar.isDateInToday(date) ? .white : thisMonth ? Color.primary : Color.gray)
                            .offset(x: (cellWidth / 2) - 8, y: ((cellHeight / 2) - 15) * -1)
                    } else {
                        Text(formatDate())
                            .padding(.trailing, 25)
                            .foregroundColor(calendar.isDateInToday(date) ? .white : thisMonth ? Color.primary : Color.gray)
                            .offset(x: (cellWidth / 2) - 8, y: ((cellHeight / 2) - 15) * -1)
                    }
                }
            }
            .frame(width: cellWidth, height: cellHeight)
            .modifier(CKMonthDayCellModifier())

            addEvents()
        }
    }

    private func isFirstDayOfMonth() -> Bool {
        return calendar.component(.day, from: date) == 1
    }

    @ViewBuilder
    private func addEvents() -> some View {

        ZStack {
            if events.count == 1 {
                event(event: events[0], yOffset: 36)
            } else if events.count == 2 {
                event(event: events[0], yOffset: 36)
                event(event: events[1], yOffset: 55)
            } else if events.count == 3 {
                event(event: events[0], yOffset: 36)
                event(event: events[1], yOffset: 52)
                event(event: events[2], yOffset: 68)
            } else if events.count > 3 {
                event(event: events[0], yOffset: 36)
                event(event: events[1], yOffset: 52)
                event(event: events[2], yOffset: 68)

                Text("+ \(events.count - 3) more")
            }
        }.padding(0)
    }

    @ViewBuilder
    private func event(event: any CKEventSchema, yOffset: CGFloat) -> some View {
        HStack{
            if event.backgroundColor.count == 7 {
                Circle()
                    .fill(event.backgroundAsColor())
                    .frame(width: 10, height: 10)
            }
            Text(event.text)
            if showTime {
                Spacer()
                Text(event.startDate.formatted(.dateTime.hour().minute()))
            }
        }
        .font(.caption)
        .frame(maxWidth: cellWidth, alignment: .leading)
        .padding([.leading, .trailing], 5)
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
        startDate: Date().dateFrom(3, 2, 2026, 1, 00),
        endDate: Date().dateFrom(3, 2, 2026, 2, 00),
        text: "Event 1 adf ads f asd f adsf asd f asd fasd",
        backCol: "#D74D64"
    )

    let event2 = CKEvent(
        startDate: Date().dateFrom(3, 2, 2026, 2, 00),
        endDate: Date().dateFrom(3, 2, 2026, 3, 00),
        text: "Event 2",
        backCol: ""
    )

    let event3 = CKEvent(
        startDate: Date().dateFrom(33, 2, 2026, 3, 30),
        endDate: Date().dateFrom(33, 2, 2026, 4, 30),
        text: "Event 3",
        backCol: "#F6D264"
    )

    return CKMonthDayCell(
        date: Date(timeIntervalSince1970: 1769977030),
        observer: CKCalendarObserver(),
        events: [event1, event2, event3],
        month: Date(),
        width: 150,
        height: 150,
        showTime: false
    )
}

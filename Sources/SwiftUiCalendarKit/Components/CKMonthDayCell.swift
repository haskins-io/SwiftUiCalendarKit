//
//  CKMonthDayCell.swift
//
//  Created by Mark Haskins on 11/04/2024.
//

import SwiftUI

struct CKMonthDayCell: View {

    @Environment(\.ckConfig)
    private var config

    @ObservedObject var observer: CKCalendarObserver

    private let calendar = Calendar.current

    private var events: [any CKEventSchema]

    private var date: Date
    private var month: Date
    private var showTime: Bool

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
                            .fill(config.currentDayColour)
                            .frame(width: 25, height: 25)
                            .offset(x: (cellWidth / 2) - 20, y: ((cellHeight / 2) - 15) * -1)
                    }

                    if isFirstDayOfMonth() {
                        Text(formatDate())
                            .padding(.trailing, 55)
                            .foregroundColor(
                                calendar.isDateInToday(date) ? .white : thisMonth ? Color.primary : Color.gray
                            )
                            .offset(x: (cellWidth / 2) - 8, y: ((cellHeight / 2) - 15) * -1)
                    } else {
                        Text(formatDate())
                            .padding(.trailing, 25)
                            .foregroundColor(
                                calendar.isDateInToday(date) ? .white : thisMonth ? Color.primary : Color.gray
                            )
                            .offset(x: (cellWidth / 2) - 8, y: ((cellHeight / 2) - 15) * -1)
                    }
                }
            }
            .frame(width: cellWidth, height: cellHeight)
            .modifier(CKMonthDayCellModifier())

            let maxRows = calcEventlistSize()
            if maxRows > 0 {
                addEvents()
            }
        }
        .background(calendar.isDateInWeekend(date) ? Color.gray.opacity(0.1) : Color.clear)
    }

    @ViewBuilder
    private func addEvents() -> some View {

        let maxRows = calcEventlistSize()

        VStack(spacing: 0) {
            ForEach(0..<maxRows, id: \.self) { index in
                if events[index].isAllDay {
                    allDayEvent(event: events[index], yOffset: 15 + (20 * CGFloat(index)))
                } else {
                    eventView(event: events[index], yOffset: 15 + (20 * CGFloat(index)))
                }
            }

            if events.count > maxRows {
                Text("+ \(events.count - maxRows) more").font(.caption)
            }
        }
        .offset(x: 0, y: 35)
        .padding(0)
    }

    @ViewBuilder
    private func eventView(event: any CKEventSchema, yOffset: CGFloat) -> some View {
        HStack {
            if event.backgroundColor.count == 7 {
                Circle()
                    .fill(event.backgroundAsColor())
                    .frame(width: 10, height: 10)
            }

            Text(CKUtils.eventText(event: event))

            if showTime {
                Spacer()
                Text(event.startDate.formatted(.dateTime.hour().minute()))
            }
        }
        .font(.caption)
        .frame(maxWidth: cellWidth, alignment: .leading)
        .padding([.leading, .trailing], 5)
        .frame(height: 20, alignment: .center)
        .onTapGesture {
            observer.eventSelected = true
            observer.event = event
        }
    }

    @ViewBuilder
    private func allDayEvent(event: any CKEventSchema, yOffset: CGFloat) -> some View {
        HStack {
            Text(CKUtils.eventText(event: event))
            Spacer()
        }
        .padding(3)
        .background(event.backgroundAsColor())
        .frame(maxWidth: cellWidth - 5, alignment: .leading)
        .frame(height: 20, alignment: .center)
        .font(.caption)
        .onTapGesture {
            observer.eventSelected = true
            observer.event = event
        }
    }
}

extension CKMonthDayCell {

    private func formatDate() -> String {

        if date.toString("d") == "1" {
            return date.toString("d MMM")
        } else {
            return date.toString("d")
        }
    }

    private func calcEventlistSize() -> Int {
        let offset: CGFloat = 25 + 25

        var maxRows = Int((cellHeight - offset) / 20)

        if maxRows > events.count {
            maxRows = events.count
        }

        return maxRows
    }

    private func isFirstDayOfMonth() -> Bool {
        return calendar.component(.day, from: date) == 1
    }
}

#Preview {

    CKMonthDayCell(
        date: Date(),
        observer: CKCalendarObserver(),
        events: testEvents,
        month: Date(),
        width: 150,
        height: 150,
        showTime: false
    )
}

//
//  CalendarViewComponent.swift
//  freya
//
//  Created by Mark Haskins on 09/04/2024.
//

import SwiftData
import SwiftUI

struct CKMonthComponent: View {

    private let calendar: Calendar
    private let monthFormatter: DateFormatter
    private let dayFormatter: DateFormatter
    private let weekDayFormatter: DateFormatter
    private let fullFormatter: DateFormatter

    @Binding private var selectedDate: Date

    var events: [any CKEventSchema] = []

    init(calendar: Calendar, date: Binding<Date>, events: [any CKEventSchema]) {

        self._selectedDate = date
        self.events = events

        self.calendar = calendar
        self.monthFormatter = DateFormatter(dateFormat: "MMMM YYYY", calendar: calendar)
        self.dayFormatter = DateFormatter(dateFormat: "d", calendar: calendar)
        self.weekDayFormatter = DateFormatter(dateFormat: "E", calendar: calendar)
        self.fullFormatter = DateFormatter(dateFormat: "dd MMM yyyy", calendar: calendar)
    }

    var body: some View {

        VStack {

            CalendarComponent(
                calendar: calendar,
                date: $selectedDate,
                content: { date in
                    ZStack {
                        Button(action: { selectedDate = date }) {
                            ZStack {

                                if calendar.isDateInToday(date) {
                                    Capsule()
                                        .fill(Color.red)
                                        .frame(width: 27, height: 27)
                                        .offset(x: 1, y: 0)
                                }

                                Text(dayFormatter.string(from: date))
                                    .padding(6)
                                    .frame(width: 33, height: 33)
                                    .foregroundColor(calendar.isDateInToday(date) ? Color.white : .primary)
                                    .cornerRadius(7)
                            }
                        }

                        if (numberOfEventsInDate(date: date) >= 2) {
                            Circle()
                                .size(CGSize(width: 5, height: 5))
                                .foregroundColor(Color.green)
                                .offset(x: CGFloat(16),
                                        y: CGFloat(35))
                        }

                        if (numberOfEventsInDate(date: date) >= 1) {
                            Circle()
                                .size(CGSize(width: 5, height: 5))
                                .foregroundColor(Color.green)
                                .offset(x: CGFloat(23),
                                        y: CGFloat(35))
                        }

                        if (numberOfEventsInDate(date: date) >= 3) {
                            Circle()
                                .size(CGSize(width: 5, height: 5))
                                .foregroundColor(Color.green)
                                .offset(x: CGFloat(30),
                                        y: CGFloat(35))
                        }
                    }
                },
                trailing: { date in
                    Text(dayFormatter.string(from: date))
                        .foregroundColor(.secondary)
                },
                header: { date in
                    Text(weekDayFormatter.string(from: date)).fontWeight(.bold)
                },
                title: { date in
                    HStack {

                        Button {
                            guard let newDate = calendar.date(
                                byAdding: .month,
                                value: -1,
                                to: selectedDate
                            ) else {
                                return
                            }

                            selectedDate = newDate
                        } label: {
                            Label(
                                title: { Text("Previous") },
                                icon: {
                                    Image(systemName: "chevron.left")
                                        .font(.title2)
                                }
                            )
                            .labelStyle(IconOnlyLabelStyle())
                            .padding(.horizontal)
                        }

                        Spacer()

                        Button {
                            selectedDate = Date.now
                        } label: {
                            Text(monthFormatter.string(from: date))
                                .foregroundColor(.blue)
                                .font(.title2)
                                .padding(2)
                        }

                        Spacer()

                        Button {
                            guard let newDate = calendar.date(
                                byAdding: .month,
                                value: 1,
                                to: selectedDate
                            ) else {
                                return
                            }

                            selectedDate = newDate
                        } label: {
                            Label(
                                title: { Text("Next") },
                                icon: {
                                    Image(systemName: "chevron.right")
                                        .font(.title2)
                                }
                            )
                            .labelStyle(IconOnlyLabelStyle())
                            .padding(.horizontal)
                        }
                    }
                }
            )
            .equatable()
        }
    }

    func dateHasEvents(date: Date) -> Bool {

        for event in events {
            if calendar.isDate(date, inSameDayAs: event.startDate) {
                return true
            }
        }

        return false
    }

    func numberOfEventsInDate(date: Date) -> Int {
        var count: Int = 0
        for event in events {
            if calendar.isDate(date, inSameDayAs: event.startDate) {
                count += 1
            }
        }
        return count
    }
}

private struct CalendarComponent<Day: View, Header: View, Title: View, Trailing: View>: View {

    @Environment(\.colorScheme)
    var colorScheme

    @Binding private var date: Date

    // Injected dependencies
    private var calendar: Calendar

    private let content: (Date) -> Day
    private let trailing: (Date) -> Trailing
    private let header: (Date) -> Header
    private let title: (Date) -> Title

    // Constants
    private let daysInWeek = 7

    public init(
        calendar: Calendar,
        date: Binding<Date>,
        @ViewBuilder content: @escaping (Date) -> Day,
        @ViewBuilder trailing: @escaping (Date) -> Trailing,
        @ViewBuilder header: @escaping (Date) -> Header,
        @ViewBuilder title: @escaping (Date) -> Title
    ) {
        self._date = date

        self.calendar = calendar
        self.content = content
        self.trailing = trailing
        self.header = header
        self.title = title
    }

    public var body: some View {

        let month = date.startOfMonth(using: calendar)
        let days = makeDays()

        VStack {

            Section(header: title(month)) { }

            VStack {

                LazyVGrid(columns: Array(repeating: GridItem(), count: daysInWeek)) {
                    ForEach(days.prefix(daysInWeek), id: \.self, content: header)
                }

                Divider()

                LazyVGrid(columns: Array(repeating: GridItem(), count: daysInWeek)) {
                    ForEach(days, id: \.self) { date in
                        if calendar.isDate(date, equalTo: month, toGranularity: .month) {
                            content(date)
                        } else {
                            trailing(date)
                        }
                    }
                }
            }
            .frame(height: days.count == 42 ? 300 : 270)
            .background(colorScheme == .dark ? Color.black : Color.white)
        }
    }
}

// MARK: - Conformances

extension CalendarComponent: Equatable {
    public static func == (lhs: CalendarComponent<Day, Header, Title, Trailing>,
                           rhs: CalendarComponent<Day, Header, Title, Trailing>) -> Bool {
        lhs.calendar == rhs.calendar && lhs.date == rhs.date
    }
}

// MARK: - Helpers

extension CalendarComponent {
    func makeDays() -> [Date] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: date),
              let monthFirstWeek = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.start),
              let monthLastWeek = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.end - 1)
        else {
            return []
        }

        let dateInterval = DateInterval(start: monthFirstWeek.start, end: monthLastWeek.end)
        return calendar.generateDays(for: dateInterval)
    }
}

struct CalendarViewComponent_Previews: PreviewProvider {

    static var previews: some View {

        CalendarComponent(calendar: Calendar(identifier: .gregorian),
                              date: .constant(Date()),
                              content: { _ in  Text("2") },
                              trailing: { _ in  Text("1").foregroundColor(.secondary) },
                              header: { _ in  Text("Mon") },
                              title: { _ in  Text("Month") }
        )
        .previewDevice("iPhone 11")
    }
}

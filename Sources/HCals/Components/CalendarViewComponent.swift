//
//  CalendarViewComponent.swift
//  freya
//
//  Created by Mark Haskins on 09/04/2024.
//

import SwiftData
import SwiftUI

struct CalendarViewComponent: View {

    private let calendar: Calendar
    private let monthFormatter: DateFormatter
    private let dayFormatter: DateFormatter
    private let weekDayFormatter: DateFormatter
    private let fullFormatter: DateFormatter

    @Binding private var selectedDate: Date

    var events: [Event] = []

    init(calendar: Calendar, date: Binding<Date>) {

        self._selectedDate = date

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
                            Text(dayFormatter.string(from: date))
                                .frame(width: 33, height: 33)
                                .foregroundColor(Color.primary)
                                .background(Color.white)
                                .cornerRadius(7)
                                .padding(3)
                        }
                    }
                },
                trailing: { date in
                    Text(dayFormatter.string(from: date))
                        .foregroundColor(.clear)
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
                                        .foregroundColor(Color.blue)
                                        .font(.title)
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
                                .font(.title2)
                                .padding(2)
                                .foregroundColor(.primary)
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
                                        .foregroundColor(Color.blue)
                                        .font(.title)
                                }
                            )
                            .labelStyle(IconOnlyLabelStyle())
                            .padding(.horizontal)
                        }
                    }
                    .padding(.bottom, 5)
                    .padding(.top, 10)
                }
            )
            .equatable()
        }
    }

    //    private func dateBackground(date: Date) -> Color {
    //
    //        if dateHasEvents(date: date) {
    //            return colourForFixture(date: date)
    //        } else {
    //            if calendar.isDateInToday(date) {
    //                return Color.gray
    //            } else {
    //
    //                if calendar.isDate(date, inSameDayAs: selectedDate) {
    //                    return Color.blue.opacity(0.10)
    //                } else {
    //                    return Color.clear
    //                }
    //            }
    //        }
    //    }

    //    private func dateHasEvents(date: Date) -> Bool {
    //
    //        for entry in fixtures where calendar.isDate(date, inSameDayAs: entry.date ?? Date()) {
    //            return true
    //        }
    //
    //        return false
    //    }
    //
    //    private func playingOnDate(date: Date) -> Bool {
    //
    //        var playing = false
    //
    //        for entry in fixtures {
    //
    //            if calendar.isDate(
    //                date,
    //                inSameDayAs: entry.date ?? Date()),
    //               (entry.playing) {
    //                playing = true
    //                break
    //            }
    //        }
    //
    //        return playing
    //    }
    //
    //    private func playingIndicator(date: Date) -> Color {
    //
    //        for entry in fixtures {
    //
    //            if calendar.isDate(date, inSameDayAs: entry.date ?? Date()), entry.playing {
    //                return Color.eGreen
    //            }
    //        }
    //
    //        return Color.clear
    //    }
    //
    //    private func colourForFixture(date: Date) -> Color {
    //
    //        for entry in fixtures where calendar.isDate(date, inSameDayAs: entry.date ?? Date()) {
    //
    //            switch Int(entry.fixtureType) {
    //            case FixtureType.friendly.rawValue:
    //                return .eGreen
    //
    //            case FixtureType.league.rawValue:
    //                return .eBlue
    //
    //            case FixtureType.competition.rawValue:
    //                return .eRed
    //
    //            default:
    //                return .eYellow
    //            }
    //        }
    //
    //        return Color.clear
    //    }
    //
    //    private func clubGameColour(date: Date) -> Color {
    //
    //        for entry in fixtures where calendar.isDate(date, inSameDayAs: entry.date ?? Date()) {
    //
    //            switch Int(entry.fixtureType) {
    //            case FixtureType.friendly.rawValue:
    //                return .eGreenDark
    //
    //            case FixtureType.league.rawValue:
    //                return .eBlueDark
    //
    //            case FixtureType.competition.rawValue:
    //                return .eRedDark
    //
    //            default:
    //                return .eYellowDark
    //            }
    //        }
    //
    //        return Color.clear
    //    }

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

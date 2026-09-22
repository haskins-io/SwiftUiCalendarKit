//
//  CKMonth.swift
//
//  Created by Mark Haskins on 09/04/2024.
//

import SwiftUI

/// `CKMonth` can be used for showing a single day calendar on a compact screen size such as an iPhone.
///
///     CKMonth(
///         observer: CKCalendarObserver(),
///         events: events,
///         date: $date
///     )
///
/// - Parameter observer: Listen to this to be notified when an event is tapped/clicked
/// - Parameter events: an array of events that conform to ``CKEvent``.
/// - Parameter date: The date for the calendar to show.

public struct CKMonth: View {

    @Environment(\.ckConfig)
    private var config

    @Environment(\.colorScheme)
    private var colorScheme

    @State var observer: CKCalendarObserver

    @Binding var calendarDate: Date

    @State private var calendarWidth: CGFloat = .zero
    @State private var calendarHeight: CGFloat = .zero

    private let calendar = Calendar.current

    private var events: [CKEvent]

    public init(
        observer: CKCalendarObserver,
        events: [CKEvent],
        date: Binding<Date>,
    ) {
        self._observer = .init(wrappedValue: observer)
        self.events = events
        self._calendarDate = date
    }

    public var body: some View {

        GeometryReader { geometry in

            VStack(alignment: .leading, spacing: 0) {

                CKCalendarHeader(currentDate: $calendarDate, addWeek: false)
                    .padding(.bottom, 5)

                CKDayHeader(currentDate: $calendarDate, width: calendarWidth, showTime: false, showDate: false)
                    .padding(.bottom, 5)

                Divider()

                // The grid takes what the headers leave, and measures *that* rather than
                // guessing at it. `((height - 70) / 6) + 4` was two guesses in one expression —
                // a 70pt header and six rows — and it was wrong twice on an iPad: the sixth row
                // ran off the bottom of the screen.
                //
                // A second `GeometryReader` is safe here for the same reason the outer one is:
                // it is sized by what the `VStack` offers it, not by the grid inside it.
                GeometryReader { grid in
                    monthGrid(in: grid.size)
                        .background(colorScheme == .dark ? Color.black : Color.white)
                }
            }
            .background(colorScheme == .dark ? Color.black : Color.white)
            .onChange(of: geometry.size, initial: true) { _, newSize in
                guard newSize.width > 0, newSize.height > 0 else {
                    return
                }

                calendarWidth = newSize.width
                calendarHeight = newSize.height
            }
        }
    }

    @ViewBuilder
    private func monthGrid(in size: CGSize) -> some View {

        let days = makeDays()
        let month = calendarDate.startOfMonth

        // Derived from the days actually being drawn. A month grid is five or six weeks
        // depending on where the 1st falls, and hard-coding six overflowed the short ones.
        let rows = max(1, Int(ceil(Double(days.count) / 7.0)))

        let widthAdjust: CGFloat = config.showWeekNumber ? 25 : 0
        let cellWidth = max(0, (size.width / 7) - widthAdjust)
        let cellHeight = max(0, size.height / CGFloat(rows))

        VStack(spacing: 0) {
            ForEach(0..<rows, id: \.self) { row in
                weekRow(
                    Array(days[(row * 7)..<min((row + 1) * 7, days.count)]),
                    month: month,
                    cellWidth: cellWidth,
                    cellHeight: cellHeight
                )
            }
        }
    }

    /// One week of the grid: seven cells, with the week's bands drawn **over** them.
    ///
    /// A `LazyVGrid` of forty-two cells cannot do this. A band spans several columns and a cell
    /// can only clip its title to one, which is how "CAA OA — Commercial Drone Operations" came
    /// to read as "CAA OA…" on a bar six columns wide. Drawing the row as a `ZStack` gives each
    /// run one view the width of the run, and the cells below simply hold the space clear —
    /// `CKMonthMetrics` is where the two sides agree on how much.
    private func weekRow(
        _ days: [Date],
        month: Date,
        cellWidth: CGFloat,
        cellHeight: CGFloat
    ) -> some View {

        let runs = CKUtils.bandRuns(week: days, events: events, calendar: calendar)

        // Capped here, once, and handed to the cells — see `CKMonthMetrics.maxBandRows`.
        let totalLanes = (runs.map(\.lane).max() ?? -1) + 1
        let laneCount = min(totalLanes, CKMonthMetrics.maxBandRows(cellHeight: cellHeight))
        let drawn = runs.filter { $0.lane < laneCount }

        // Per day, not per row. A cell with no bar over it reserves nothing and starts its own
        // events at the top; the day under a bar still reserves every lane above it, holes
        // included, or the bars stop being level. See `CKUtils.bandRowCounts`.
        let reserved = CKUtils.bandRowCounts(runs: drawn, columns: days.count)
        let hidden = CKUtils.bandCounts(runs: runs.filter { $0.lane >= laneCount }, columns: days.count)

        return ZStack(alignment: .topLeading) {

            HStack(spacing: 0) {
                ForEach(Array(days.indices), id: \.self) { index in
                    CKMonthDayCell(
                        date: days[index],
                        observer: observer,
                        events: eventsForDay(day: days[index]),
                        reservedBandRows: reserved[index],
                        hiddenBands: hidden[index],
                        month: month,
                        width: cellWidth,
                        height: cellHeight
                    )
                }
            }

            ForEach(drawn) { run in
                bandBar(run, days: days, month: month)
                    .frame(width: cellWidth * CGFloat(run.length), height: CKMonthMetrics.rowHeight)
                    .offset(
                        x: cellWidth * CGFloat(run.startIndex),
                        y: CKMonthMetrics.firstBandOffset
                        + CGFloat(run.lane) * (CKMonthMetrics.rowHeight + CKMonthMetrics.rowSpacing)
                    )
            }
        }
        .frame(height: cellHeight)
    }

    /// One run, drawn as a single bar across the days it covers.
    ///
    /// Rounded only at the ends the band actually has in this row — a square edge says it carries
    /// on into the week before or after, which is the whole vocabulary a multi-week band has.
    private func bandBar(_ run: CKBandRun, days: [Date], month: Date) -> some View {

        let event = run.event
        let firstDay = days[run.startIndex]
        let lastDay = days[min(run.startIndex + run.length - 1, days.count - 1)]

        let startsHere = calendar.isDate(event.startDate, inSameDayAs: firstDay)
        let endsHere = calendar.isDate(event.endDate, inSameDayAs: lastDay)
        let inMonth = calendar.isDate(firstDay, equalTo: month, toGranularity: .month)

        return HStack(spacing: 4) {

            if !event.systemImage.isEmpty {
                Image(systemName: event.systemImage)
                    .font(.caption2)
                    .foregroundStyle(event.tint)
            }

            Text(event.title)
                .font(.caption2)
                .lineLimit(1)
                .truncationMode(.tail)
                .foregroundStyle(inMonth ? .primary : .secondary)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 5)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            UnevenRoundedRectangle(
                topLeadingRadius: startsHere ? 3 : 0,
                bottomLeadingRadius: startsHere ? 3 : 0,
                bottomTrailingRadius: endsHere ? 3 : 0,
                topTrailingRadius: endsHere ? 3 : 0
            )
            .fill(event.tint.opacity(0.18))
        }
        .contentShape(.rect)
        .onTapGesture {
            observer.event = event
        }
    }
}

extension CKMonth {

    private func makeDays() -> [Date] {
        calendar.monthGridDays(for: calendarDate)
    }

    /// The day's own events.
    private func eventsForDay(day: Date) -> [CKEvent] {
        events.filter {
            CKUtils.doesEventOccurOnDate(event: $0, date: day) && !$0.isMultiDay(in: calendar)
        }
    }
}

#Preview {
    return CKMonth(
        observer: CKCalendarObserver(),
        events: testEvents,
        date: .constant(Date())
    )
}

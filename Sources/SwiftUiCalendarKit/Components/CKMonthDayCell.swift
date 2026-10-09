//
//  CKMonthDayCell.swift
//
//  Created by Mark Haskins on 11/04/2024.
//

import SwiftUI

/// One day in the month grid.
struct CKMonthDayCell: View {

    @Environment(\.locale)
    private var locale

    @Environment(\.ckConfig)
    private var config

    @State var observer: CKCalendarObserver

    private let calendar = Calendar.current

    /// The day's own events — never a multi-day band, which travels in `bands`.
    private let events: [CKEvent]

    /// How many band rows to leave clear at the top — **this day's**, not the week's.
    private let reservedBandRows: Int

    /// Bands the row could not fit, so the cell's "+ N more" can account for them.
    private let hiddenBands: Int

    private let date: Date
    private let month: Date

    private let cellWidth: CGFloat
    private let cellHeight: CGFloat

    private let rowHeight = CKMonthMetrics.rowHeight
    private let cellInset = CKMonthMetrics.inset

    init(
        date: Date,
        observer: CKCalendarObserver,
        events: [CKEvent],
        reservedBandRows: Int = 0,
        hiddenBands: Int = 0,
        month: Date,
        width: CGFloat,
        height: CGFloat
    ) {
        self._observer = .init(wrappedValue: observer)

        self.date = date
        self.month = month
        self.events = events
        self.reservedBandRows = reservedBandRows
        self.hiddenBands = hiddenBands

        // Clamped, and never negative. `CKMonth` waits to be measured before drawing the grid,
        // so these should always be positive; a caller that gets it wrong should draw nothing
        // rather than report "Invalid frame dimension" once per cell, 42 times a pass.
        self.cellWidth = max(0, width)
        self.cellHeight = max(0, height)
    }

    var body: some View {

        VStack(alignment: .leading, spacing: CKMonthMetrics.rowSpacing) {

            header

            if visibleBandRows > 0 {
                Color.clear.frame(height: CKMonthMetrics.bandsHeight(visibleBandRows))
            }

            ForEach(visibleEvents) { event in
                chip(for: event)
            }

            if hiddenCount > 0 {
                HStack {
                    Spacer()

                    Text(CKStrings.moreEvents(hiddenCount).locale(self.locale))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .padding(.leading, 5)
                        .onTapGesture {
                            observer.events = events
                        }

                    Spacer()
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, cellInset)
        .padding(.vertical, CKMonthMetrics.verticalPadding)
        .frame(width: cellWidth, height: cellHeight, alignment: .topLeading)
        .background(calendar.isDateInWeekend(date) ? Color.gray.opacity(0.08) : Color.clear)
        .modifier(CKMonthDayCellModifier())
    }
}

// MARK: - Pieces
extension CKMonthDayCell {

    private var header: some View {
        HStack(spacing: 2) {

            Spacer(minLength: 0)

            Text(date.formatted(.dateTime.day().locale(self.locale)))
                .font(.caption)
                .fontWeight(isToday ? .bold : .regular)
                .foregroundStyle(dateColour)
                .padding(4)
                .background {
                    if isToday {
                        RoundedRectangle(cornerRadius: 3).fill(.red)
                    }
                }
        }
        .frame(height: CKMonthMetrics.headerHeight)
    }

    /// One event.
    ///
    /// A band is washed with its own tint so a trip or a permit reads as a bar across the week;
    /// everything else is a spine and a title. Both are the same height and the same shape, so a
    /// cell holding one of each still reads as a list.
    private func chip(for event: CKEvent) -> some View {
        HStack(spacing: 4) {

            RoundedRectangle(cornerRadius: 1.5)
                .fill(event.tint)
                .frame(width: 3)

            Text(event.title)
                .font(.caption2)
                .lineLimit(1)
                .truncationMode(.tail)
                .foregroundStyle(isThisMonth ? .primary : .secondary)

            Spacer(minLength: 0)
        }
        .padding(.trailing, 2)
        .frame(height: rowHeight)
        .contentShape(.rect)
        .onTapGesture {
            observer.event = event
        }
    }
}

// MARK: - What fits
extension CKMonthDayCell {

    private var isToday: Bool {
        calendar.isDateInToday(date)
    }

    private var isThisMonth: Bool {
        calendar.isDate(date, equalTo: month, toGranularity: .month)
    }

    private var dateColour: Color {
        if isToday {
            return .white
        }

        return isThisMonth ? .primary : .secondary
    }

    /// Exactly what the row asked for.
    ///
    /// The cell does **not** second-guess this. `CKMonth` has already capped it with
    /// `CKMonthMetrics.maxBandRows` and counted the lanes reaching this particular column, and a
    /// cell that reserved less than the row draws is a bar through the middle of "+ 1 more" —
    /// which is what a second, independent calculation here produced.
    private var visibleBandRows: Int {
        reservedBandRows
    }

    /// Which events fit and how many do not — see `CKMonthCellLayout`.
    private var layout: CKMonthCellLayout {
        CKMonthCellLayout(
            events: events,
            reservedBandRows: visibleBandRows,
            hiddenBands: hiddenBands,
            cellHeight: cellHeight
        )
    }

    private var visibleEvents: [CKEvent] {
        layout.visible
    }

    private var hiddenCount: Int {
        layout.hiddenCount
    }
}

#Preview {
    CKMonthDayCell(
        date: Date(),
        observer: CKCalendarObserver(),
        events: testEvents,
        reservedBandRows: 1,
        month: Date(),
        width: 180,
        height: 150
    )
}

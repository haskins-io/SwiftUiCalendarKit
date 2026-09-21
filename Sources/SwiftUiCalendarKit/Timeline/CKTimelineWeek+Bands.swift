//
//  File.swift
//  SwiftUiCalendarKit
//
//  Created by Mark Haskins on 21/09/2026.
//

import SwiftUI

/// The all-day strip above the week's hour grid: multi-day bands, and each day's own whole-day
/// chips beneath them.
///
/// Split from `CKTimelineWeek` because it is the one part of that view that does not use the
/// `Grid`: a band spans several columns, and a `GridRow` can only give it one cell — which is
/// what clipped "CAA OA — Commercial Drone Operations" down to "CAA OA…" while its wash ran the
/// full width of the week.
///
/// The chips joined it on 2026-09-02. They had been a `GridRow` of their own below the bands,
/// which is exactly the arrangement that made every column start below the deepest band in the
/// week rather than below its own.
extension CKTimelineWeek {

    /// The whole strip above the hour grid: multi-day bands, and each day's own chips beneath
    /// the bands that actually reach it.
    ///
    /// One area rather than two stacked rows. As two rows the chips began below the deepest band
    /// anywhere in the week, so a Tuesday with three deadlines and no band over it started two
    /// blank rows down because a trip ran across the weekend — space held clear for bars that
    /// were never going to be drawn there.
    ///
    /// Positioned rather than gridded: a run is offset to its start column and sized to its
    /// length, so the title has the whole bar to sit in. Everything below stacks in the same
    /// lane arithmetic, and the strip is exactly as tall as the deepest column — nothing to
    /// show, no strip.
    ///
    /// - Parameter chips: one entry per column, in week order — the day's single-day all-day
    ///   events and deadlines.
    @ViewBuilder
    func allDayArea(runs: [CKBandRun], chips: [[CKEvent]], week: [WeekDay]) -> some View {

        // Per column, and only for the bands that reach it — see `CKUtils.bandRowCounts`.
        let reserved = CKUtils.bandRowCounts(runs: runs, columns: week.count)
        let rows = zip(reserved, chips).map { $0 + $1.count }.max() ?? 0

        if rows > 0 {
            ZStack(alignment: .topLeading) {

                ForEach(runs) { run in
                    bandBar(run, week: week)
                        .frame(width: columnWidth * CGFloat(run.length), height: bandHeight)
                        .offset(
                            x: timebarWidth + columnWidth * CGFloat(run.startIndex),
                            y: laneOffset(run.lane)
                        )
                }

                ForEach(Array(week.indices), id: \.self) { index in
                    VStack(spacing: bandSpacing) {
                        ForEach(chips[index]) { event in
                            eventChip(event: event)
                        }
                    }
                    .frame(width: columnWidth)
                    .offset(
                        x: timebarWidth + columnWidth * CGFloat(index),
                        y: laneOffset(reserved[index])
                    )
                }
            }
            .frame(height: laneOffset(rows) - bandSpacing, alignment: .topLeading)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 4)
        }
    }

    /// The top of lane `lane`, measured from the top of the strip.
    ///
    /// Named because four places need it — the bars, each column's chips, and the strip's own
    /// height — and a band and the chip beneath it disagreeing by two points is the kind of
    /// thing nothing catches.
    private func laneOffset(_ lane: Int) -> CGFloat {
        CGFloat(lane) * (bandHeight + bandSpacing)
    }

    /// One run, drawn as a single bar.
    ///
    /// Rounded only at the ends the band actually has in this row: a square edge says it carries
    /// on into the week before or after, which is the whole vocabulary a multi-week band has.
    private func bandBar(_ run: CKBandRun, week: [WeekDay]) -> some View {

        let event = run.event
        let firstDay = week[run.startIndex].date
        let lastDay = week[min(run.startIndex + run.length - 1, week.count - 1)].date

        let startsHere = calendar.isDate(event.startDate, inSameDayAs: firstDay)
        let endsHere = calendar.isDate(event.endDate, inSameDayAs: lastDay)

        return HStack(spacing: 4) {

            if !event.systemImage.isEmpty {
                Image(systemName: event.systemImage)
                    .foregroundStyle(event.tint)
            }

            Text(event.title)
                .bold()
                .lineLimit(1)
                .truncationMode(.tail)

            Spacer(minLength: 0)
        }
        .font(.caption)
        .foregroundStyle(.primary)
        .padding(.horizontal, 6)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            UnevenRoundedRectangle(
                topLeadingRadius: startsHere ? 4 : 0,
                bottomLeadingRadius: startsHere ? 4 : 0,
                bottomTrailingRadius: endsHere ? 4 : 0,
                topTrailingRadius: endsHere ? 4 : 0
            )
            .fill(event.tint.opacity(0.35))
        }
        .contentShape(.rect)
        .onTapGesture {
            observer.event = event
        }
    }

    /// A single-day all-day event or a deadline, in the strip above the grid.
    @ViewBuilder
    private func eventChip(event: CKEvent) -> some View {

        HStack(spacing: 4) {
            if !event.systemImage.isEmpty {
                Image(systemName: event.systemImage)
                    .foregroundStyle(event.tint)
            }

            Text(event.title)
                .bold()
                .lineLimit(1)
                .truncationMode(.tail)

            Spacer(minLength: 0)
        }
        .foregroundStyle(.primary)
        .font(.caption)
        .padding(.horizontal, 6)
        .frame(height: bandHeight)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(event.tint.opacity(0.35))
        )
        // Reporting the tap is the whole reason a chip is a chip rather than a label. Neither
        // this nor the fillers it replaced ever told the observer anything, so every bar in the
        // strip above the grid was inert.
        .contentShape(.rect)
        .onTapGesture {
            observer.event = event
        }
    }
}

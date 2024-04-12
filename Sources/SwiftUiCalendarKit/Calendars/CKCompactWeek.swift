//
//  CalendarCompactWeekView.swift
//  freya
//
//  Created by Mark Haskins on 09/04/2024.
//

import SwiftData
import SwiftUI

public struct CKCompactWeek: View {

    @State private var currentDay: Date = .init()
    
    private var events: [any CKEventSchema]

    private let calendar = Calendar(identifier: .gregorian)

    public init(events: [any CKEventSchema]) {
        self.events = events
    }

    public var body: some View {

        ScrollView(.vertical, showsIndicators: false) {
            timelineView()
                .padding(15)
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            headerView()
        }
    }

    /// - Timeline View
    @ViewBuilder
    func timelineView() -> some View {

        ScrollViewReader { proxy in
            let hours = Calendar.current.hours
            let midHour = hours[hours.count / 2]

            VStack {
                ForEach(hours, id: \.self) { hour in
                    timelineViewRow(hour).id(hour)
                }
            }
            .onAppear {
                proxy.scrollTo(midHour)
            }
        }
    }

    /// - Timeline ViewRow
    @ViewBuilder
    func timelineViewRow(_ date: Date) -> some View {

        HStack(alignment: .top) {
            Text(date.toString("h a"))
                .frame(width: 45, alignment: .leading)

            /// - Filtering Tasks
            let calendar = Calendar.current
            let filteredTasks = events.filter {
                if let hour = calendar.dateComponents([.hour], from: date).hour,
                   let taskHour = calendar.dateComponents([.hour], from: $0.startDate).hour,
                   hour == taskHour && calendar.isDate($0.startDate, inSameDayAs: currentDay) {
                    return true
                }
                return false
            }

            if filteredTasks.isEmpty {
                Rectangle()
                    .stroke(.gray.opacity(0.5), style: StrokeStyle(lineWidth: 0.5, lineCap: .butt, lineJoin: .bevel, dash: [5], dashPhase: 5))
                    .frame(height: 0.5)
                    .offset(y: 10)
            } else {
                VStack(spacing: 10) {
                    ForEach(filteredTasks, id: \.anyHashableID) { task in
                        taskRow(task)
                    }
                }
            }
        }
        .hAlign(.leading)
        .padding(.vertical, 15)
    }

    @ViewBuilder
    func taskRow(_ task: any CKEventSchema) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(task.text.uppercased())
//                .foregroundColor(task.category.color)
        }
        .hAlign(.leading)
        .padding(12)
        .background {
            ZStack(alignment: .leading) {
                Rectangle()
//                    .fill(task.category.color)
                    .frame(width: 4)

                Rectangle()
//                    .fill(task.category.color.opacity(0.25))
            }
        }
    }

    /// - Header View
    @ViewBuilder
    func headerView() -> some View {
        VStack {
            /// - Today Date in String
            Text(Date().toString("MMM YYY"))
                .hAlign(.leading)
                .padding(.top, 15)

            /// - Current Week row
            weekRow()
        }
        .padding(15)
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
            ForEach(calendar.currentWeek(today: currentDay)) { weekDay in

                let status = Calendar.current.isDate(weekDay.date, inSameDayAs: currentDay)

                VStack(spacing: 6) {
                    Text(weekDay.string.prefix(3))
                    Text(weekDay.date.toString("dd"))
                }
                .foregroundColor(status ? Color.blue : .gray)
                .hAlign(.center)
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        currentDay = weekDay.date
                    }
                }
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, -15)
    }
}

#Preview {
    CKCompactWeek(events: [])
}

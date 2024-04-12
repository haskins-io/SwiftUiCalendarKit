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

struct MonthDayCell: View {

    let calendar = Calendar(identifier: .gregorian)

    private var date: Date
    private var month: Date

    var events: [any CKEventSchema]

    private var cellWidth: CGFloat
    private var cellHeight: CGFloat

    init(date: Date, events: [any CKEventSchema], month: Date, width: CGFloat, height: CGFloat) {

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
                Text(formatDate())
                    .padding(.trailing, 15)
                    .foregroundColor(thisMonth ? Color.primary : Color.gray)
                    .offset(x: (cellWidth / 2) - 10, y: ((cellHeight / 2) - 20) * -1)
            }
            .frame(width: cellWidth, height: cellHeight)
            .modifier(CKMonthDayCellModifier())

            addEvents()
        }
    }

    @ViewBuilder
    private func addEvents() -> some View {

        return ZStack {
            if events.count == 1 {
                event(event: events[0], yOffset: 30)
            }

            if events.count == 2 {
                event(event: events[0], yOffset: 30)
                event(event: events[1], yOffset: 53)
            }

            if events.count == 3 {
                event(event: events[0], yOffset: 30)
                event(event: events[1], yOffset: 53)
                event(event: events[3], yOffset: 76)
            }
        }.padding(0)
    }

    @ViewBuilder
    private func event(event: any CKEventSchema, yOffset: CGFloat) -> some View {
        HStack{
            Text(event.text).foregroundStyle(.white)
            Spacer()
            Text(event.startDate.formatted(.dateTime.hour().minute())).bold().foregroundStyle(.white)

        }
        .font(.caption)
        .frame(maxWidth: cellWidth, alignment: .leading)
        .padding(4)
        .frame(height: 20, alignment: .center)
        .background(
            RoundedRectangle(cornerRadius: 3)
                .fill(.blue).opacity(0.8)
        )
        .padding(.trailing, 2)
        .offset(x: 0, y: yOffset)
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
    MonthDayCell(date: Date(),events: [], month: Date(), width: 150, height: 150)
}

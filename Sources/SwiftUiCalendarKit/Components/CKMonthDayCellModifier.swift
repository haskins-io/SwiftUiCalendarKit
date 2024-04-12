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

    private var cellWidth: CGFloat
    private var cellHeight: CGFloat

    init(date: Date, month: Date, width: CGFloat, height: CGFloat) {
        self.date = date
        self.month = month
        cellWidth = width
        cellHeight = height
    }

    var body: some View {

        let thisMonth = calendar.isDate(date, equalTo: month, toGranularity: .month)

        VStack {
            Text(formatDate())
                .padding(.trailing, 15)
                .foregroundColor(thisMonth ? Color.primary : Color.gray)
                .offset(x: (cellWidth / 2) - 20, y: ((cellHeight / 2) - 20) * -1)
        }
        .frame(width: cellWidth, height: cellHeight)
        .modifier(CKMonthDayCellModifier())
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
    MonthDayCell(date: Date(), month: Date(), width: 150, height: 150)
}

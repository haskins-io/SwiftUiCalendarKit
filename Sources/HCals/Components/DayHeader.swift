//
//  DayHeader.swift
//  Freya
//
//  Created by Mark Haskins on 11/04/2024.
//

import SwiftUI

struct DayHeader: View {

    @Binding var currentDate: Date

    var width: CGFloat

    var showTime: Bool
    var showDate: Bool

    private let calendar = Calendar(identifier: .gregorian)

    var body: some View {

        var widthOfset: CGFloat = 0
        if showTime {
            widthOfset = 45
        }

        let width = (width - widthOfset) / CGFloat(7)

        return ZStack {

            ForEach(Array(calendar.currentWeek(today: currentDate).enumerated()), id: \.offset) { index, weekDay in

                let xOffset = (width * CGFloat(index)) + widthOfset
                let status = Calendar.current.isDate(weekDay.date, inSameDayAs: Date())

                HStack(alignment: .center) {
                    Text(weekDay.string.prefix(3))
                    if showDate {
                        Text(weekDay.date.toString("dd")).foregroundColor(status ? Color.red : .black)
                    }
                }
                .frame(maxWidth: width, alignment: .center)
                .offset(x: xOffset, y: 0)
            }
        }
        .padding(.top, 2)
    }
}

 #Preview {
     DayHeader(currentDate: .constant(Date()), width: 1500, showTime: true, showDate: false)
 }

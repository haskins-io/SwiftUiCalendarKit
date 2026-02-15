//
//  DayHeader.swift
//  Freya
//
//  Created by Mark Haskins on 11/04/2024.
//

import SwiftUI

struct CKDayHeader: View {

    @Environment(\.ckConfig) private var config

    @Binding var currentDate: Date

    var width: CGFloat

    var showTime: Bool
    var showDate: Bool

    private let calendar = Calendar.current

    var body: some View {

        var widthOfset: CGFloat = 0
        if showTime {
            widthOfset = 40
        }

        let width = (width - widthOfset) / CGFloat(7)

        return ZStack {

            let currentWeek = currentDate.fetchWeek()

            ForEach(Array(currentWeek.enumerated()), id: \.offset) { index, weekDay in

                let status = Calendar.current.isDate(weekDay.date, inSameDayAs: Date())
                let xOffset = (width * CGFloat(index)) + widthOfset

                VStack(alignment: .center) {
                    Text(weekDay.string.prefix(3))
                    if showDate {
                        ZStack {
                            RoundedRectangle(cornerRadius: 5)
                                .fill(Calendar.current.isDate(weekDay.date, inSameDayAs: Date()) ?
                                      config.currentDayColour : calendar.isDate(weekDay.date, inSameDayAs: currentDate) ? Color.blue.opacity(0.10) :
                                        .clear)
                                .frame(width: 27, height: 27)

                            Text(weekDay.date.toString("dd"))
                                .foregroundColor(status ? Color.white : .primary)

                        }
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
     CKDayHeader(currentDate: .constant(Date()), width: 1500, showTime: true, showDate: true)
 }

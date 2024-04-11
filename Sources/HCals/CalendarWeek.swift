//
//  CalendarWeekView.swift
//  freya
//
//  Created by Mark Haskins on 09/04/2024.
//

import SwiftData
import SwiftUI

struct CalendarWeek: View {

    @State var currentDay = Date()

    var events: [Event]

    let calendar = Calendar(identifier: .gregorian)
    let hourHeight = 60.0

    var body: some View {

        GeometryReader { proxy in
            VStack(alignment: .leading) {

                CalendarHeader(currentDate: $currentDay, addWeek: true)

                DayHeader(currentDate: $currentDay, width: proxy.size.width, showTime: true, showDate: true)

                Divider()

                timeline(proxy: proxy)
            }
            .background(Color.white)
        }
    }

    private func timeline(proxy: GeometryProxy) -> some View {

        ScrollView {

            ZStack(alignment: .topLeading) {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(0..<24) { hour in
                        HStack {
                            Text(String(format: "%02d:00", hour))
                                .font(.caption)
                                .frame(width: 40, alignment: .trailing)
                            Color.gray
                                .frame(height: 1)
                        }
                        .frame(height: hourHeight)
                    }
                }

                ForEach(events) { event in
                    eventCell(event, startDay: 8, width: (proxy.size.width - CGFloat(40)) / 7)
                }

                ForEach(1..<7) { day in

                    let ofset: CGFloat = ((proxy.size.width - CGFloat(40)) / CGFloat(7)) * CGFloat(day)

                    Rectangle()
                        .fill(Color.gray)
                        .frame(width: 1,
                               height: 1460,
                               alignment: .center)

                        .offset(x: ofset + 45, y: 10)
                }
            }
        }
    }

    func eventCell(_ event: Event, startDay: Int, width: CGFloat) -> some View {

        let duration = event.endDate.timeIntervalSince(event.startDate)
        let height = duration / 60 / 60 * hourHeight

        let calendar = Calendar.current
        let day = calendar.component(.day, from: event.startDate)
        let hour = calendar.component(.hour, from: event.startDate)
        let minute = calendar.component(.minute, from: event.startDate)

        let yOffset = (Double(hour) * (hourHeight)) + Double(minute)
        let xOffset = CGFloat((day - startDay)) * (width)

        return VStack(alignment: .leading) {
            Text(event.title).bold()
        }
        .font(.caption)
        .frame(maxWidth: width - 14, alignment: .leading)
        .padding(4)
        .frame(height: height, alignment: .top)
        .background(
            RoundedRectangle(cornerRadius: 3)
                .fill(.blue).opacity(0.8)
        )
        .padding(.trailing, 30)
        .offset(x: CGFloat(xOffset + 45), y: yOffset + 30)
    }
}

#Preview {
    CalendarWeek(events: [])
}

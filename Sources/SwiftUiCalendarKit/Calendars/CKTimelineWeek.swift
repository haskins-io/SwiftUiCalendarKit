//
//  CalendarWeekView.swift
//  freya
//
//  Created by Mark Haskins on 09/04/2024.
//

import SwiftData
import SwiftUI

public struct CKTimelineWeek: View {

    @State var currentDay = Date()

    private var events: [any CKEventSchema]

    private let calendar = Calendar(identifier: .gregorian)
    private let hourHeight = 60.0

    public init(events: [any CKEventSchema]) {
        self.events = events
    }

    public var body: some View {

        GeometryReader { proxy in
            VStack(alignment: .leading) {

                CKCalendarHeader(currentDate: $currentDay, addWeek: true)

                CKDayHeader(currentDate: $currentDay, width: proxy.size.width, showTime: true, showDate: true)

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

                ForEach(events, id: \.anyHashableID) { event in
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

    func eventCell(_ event: any CKEventSchema, startDay: Int, width: CGFloat) -> some View {

        let duration = event.endDate.timeIntervalSince(event.startDate)
        let height = duration / 60 / 60 * hourHeight

        let calendar = Calendar.current
        let day = calendar.component(.day, from: event.startDate)
        let hour = calendar.component(.hour, from: event.startDate)
        let minute = calendar.component(.minute, from: event.startDate)

        let yOffset = (Double(hour) * (hourHeight)) + Double(minute)
        let xOffset = CGFloat((day - startDay)) * (width)

        return VStack(alignment: .leading) {
            Text(event.startDate.formatted(.dateTime.hour().minute()))
            Text(event.text).bold()
        }
        .font(.caption)
        .frame(maxWidth: width - 9, alignment: .leading)
        .padding(4)
        .frame(height: height, alignment: .top)
        .background(
            RoundedRectangle(cornerRadius: 3)
                .fill(.blue).opacity(0.8)
        )
        .padding(.trailing, 30)
        .offset(x: CGFloat(xOffset + 46), y: yOffset + 30)
    }
}

#Preview {
    CKTimelineWeek(events: [])
}

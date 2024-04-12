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

        return ScrollView {

            ZStack(alignment: .topLeading) {
                
                CKTimeline()

                ForEach(events, id: \.anyHashableID) { event in

                    CKEventCell(
                        event,
                        width: ((proxy.size.width - CGFloat(40)) / 7),
                        applyXOffset: true,
                        startDay: calendar.firstDateOfWeek(week: currentDay)
                    )
                }

                ForEach(1..<7) { day in

                    let offset: CGFloat = ((proxy.size.width - CGFloat(40)) / CGFloat(7)) * CGFloat(day)

                    Rectangle()
                        .fill(Color.gray)
                        .frame(width: 1,
                               height: 1460,
                               alignment: .center)
                        .offset(x: offset + 45, y: 10)
                }
            }
        }
    }
}

#Preview {
    CKTimelineWeek(events: [])
}

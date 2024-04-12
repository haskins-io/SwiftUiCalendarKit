//
//  SingleTimeline.swift
//  freya
//
//  Created by Mark Haskins on 03/04/2024.
//

import SwiftUI

public struct CKTimelineDay: View {

    @State private var date = Date()

    private var events: [any CKEventSchema]

    private let hourHeight = 60.0

    public init(events: [any CKEventSchema]) {
        self.events = events
    }

    public var body: some View {
        dayView()
    }

    private func sidebar() -> some View {

        DatePicker(
            "",
            selection: $date,
            displayedComponents: [.date]
        )
        .datePickerStyle(.graphical)
    }

    private func dayView() -> some View {

        VStack(alignment: .leading) {

            // Date headline
            HStack {
                Text(date.formatted(.dateTime.day().month(.wide)))
                    .bold()
                Text(date.formatted(.dateTime.year()))
            }
            .padding(.leading, 10)
            .padding(.top, 5)
            .font(.title)
            Text(date.formatted(.dateTime.weekday(.wide))).padding(.leading, 10)

            Divider().padding([.leading, .trailing], 10)

            ScrollView {
                ZStack(alignment: .topLeading) {

                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(0..<24) { hour in
                            HStack {
                                Text(String(format: "%02d:00", hour))
                                    .font(.caption)
                                    .frame(width: 40, alignment: .trailing)
                                Color.gray
                                    .padding(.trailing, 10)
                                    .frame(height: 1)
                            }
                            .frame(height: hourHeight)
                        }
                    }
                    
                    ForEach(events, id: \.anyHashableID) { event in
                        eventCell(event)
                    }
                }
            }
        }
        .background(Color.white)
    }

    private func eventCell(_ event: any CKEventSchema) -> some View {

        let duration = event.endDate.timeIntervalSince(event.startDate)
        let height = duration / 60 / 60 * hourHeight

        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: event.startDate)
        let minute = calendar.component(.minute, from: event.startDate)
        let offset = (Double(hour) * (hourHeight)) + Double(minute)

        return VStack(alignment: .leading) {
            Text(event.startDate.formatted(.dateTime.hour().minute()))
            Text(event.text).bold()
        }
        .font(.caption)
        .frame(maxWidth: .infinity - 14, alignment: .leading)
        .padding(4)
        .frame(height: height, alignment: .top)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(.teal).opacity(0.5)
        )
        .padding(.trailing, 30)
        .offset(x: 50, y: offset + 30)
    }
}

#Preview {
    CKTimelineDay(events: [])
}

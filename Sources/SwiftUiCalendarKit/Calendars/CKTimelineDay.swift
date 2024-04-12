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

    private let calendar = Calendar(identifier: .gregorian)

    public init(events: [any CKEventSchema]) {
        self.events = events
    }

    public var body: some View {
        dayView()
    }

    private func dayView() -> some View {

        GeometryReader { proxy in

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

                        CKTimeline()

                        ForEach(events, id: \.anyHashableID) { event in
                            if calendar.isDate(event.startDate, inSameDayAs: date) {
                                CKEventCell(event, width: (proxy.size.width - 70), applyXOffset: false)
                            }
                        }
                    }
                }
            }
            .background(Color.white)
        }
    }
}

#Preview {
    CKTimelineDay(events: [])
}

//
//  SwiftUIView.swift
//  
//
//  Created by Mark Haskins on 12/04/2024.
//

import SwiftUI

struct CKEventCell: View {

    private let duration: CGFloat
    private let height: CGFloat

    private let day: Int
    private let hour: Int
    private let minute: Int

    private let xOffset: CGFloat
    private let yOffset: CGFloat

    private let event: any CKEventSchema
    private let width: CGFloat

    init(_ event: any CKEventSchema, width: CGFloat, applyXOffset: Bool, startDay: Int? = 0) {

        self.event = event

        let calendar = Calendar(identifier: .gregorian)

        duration = event.endDate.timeIntervalSince(event.startDate)
        height = duration / 60 / 60 * CKTimeline.hourHeight

        day = calendar.component(.day, from: event.startDate)
        hour = calendar.component(.hour, from: event.startDate)
        minute = calendar.component(.minute, from: event.startDate)

        if applyXOffset, let start = startDay {
            xOffset = (CGFloat(day - start) * width) + 46
            self.width = width - 9
        } else {
            xOffset = 50
            self.width = width
        }

        yOffset = (Double(hour) * (CKTimeline.hourHeight)) + Double(minute)
    }

    var body: some View {

        VStack(alignment: .leading) {
            Text(event.startDate.formatted(.dateTime.hour().minute()))
            Text(event.text).bold()
        }
        .font(.caption)
        .frame(maxWidth: width, alignment: .leading)
        .padding(4)
        .frame(height: height, alignment: .top)
        .background(
            RoundedRectangle(cornerRadius: 3)
                .fill(.teal).opacity(0.8)
        )
        .padding(.trailing, 30)
        .offset(x: xOffset, y: yOffset + 30)
    }
}

//#Preview {
//    CKEventCell()
//}

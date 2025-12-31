//
//  SwiftUIView.swift
//  
//
//  Created by Mark Haskins on 12/04/2024.
//

import SwiftUI

struct CKTimeline: View {

    let startHour: Int
    let endHour: Int

    static let hourHeight = 60.0

    init(props: CKProperties? = CKProperties()) {

        if let properties = props {
            self.startHour = properties.timelineStartHour
            self.endHour = properties.timelineEndHour
        } else {
            self.startHour = 0
            self.endHour = 24
        }
    }

    var body: some View {

        VStack(alignment: .leading, spacing: 0) {

            ForEach(startHour..<endHour) { hour in

                HStack {
                    Text(String(format: "%02d:00", hour))
                        .font(.caption)
                        .frame(width: 40, alignment: .trailing)
                    Color.gray
                        .padding(.trailing, 10)
                        .frame(height: 1)
                }
                .frame(height: CKTimeline.hourHeight)
            }
        }
    }

}

#Preview {
    CKTimeline()
}

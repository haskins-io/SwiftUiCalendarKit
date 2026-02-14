//
//  SwiftUIView.swift
//  
//
//  Created by Mark Haskins on 12/04/2024.
//

import SwiftUI

struct CKTimeline: View {

    private let startHour = 0
    private let endHour = 24

    private let showLines: Bool

    private let properties: CKProperties?

    static let hourHeight = 60.0

    init(props: CKProperties? = CKProperties(), showlines: Bool = true) {
        self.showLines = showlines
        self.properties = props
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

    private func isOutOfHours(hour: Int) -> Bool {
        guard let props = properties else {
            return false
        }

        if hour < props.timelineStartHour || hour >= props.timelineEndHour {
            return true
        }

        return false
    }

}

#Preview {
    CKTimeline(showlines: true)
}

//
//  CKTimeline.swift
//  
//
//  Created by Mark Haskins on 12/04/2024.
//

import SwiftUI

struct CKTimeline: View {

    @Environment(\.ckConfig) private var config

    static let hourHeight = 60.0

    var body: some View {

        VStack(alignment: .leading, spacing: 0) {

            ForEach(0..<24) { hour in

                ZStack {
                    Rectangle()
                        .fill(isOutOfHours(hour: hour) ? Color.gray.opacity(0.2) : Color.clear)
                        .frame(height: CKTimeline.hourHeight)
                        .offset(x: 0, y: 30)

                    HStack {
                        Text(String(format: "%02d:00", hour))
                            .font(.caption)
                            .frame(width: 40, alignment: .trailing)
                        Color.gray
                            .frame(height: 1)
                    }
                    .frame(height: CKTimeline.hourHeight)
                }
            }
        }
    }

    private func isOutOfHours(hour: Int) -> Bool {

        if hour < config.dayStart || hour >= config.dayEnd {
            return true
        }

        return false
    }
}

#Preview {
    CKTimeline()
}

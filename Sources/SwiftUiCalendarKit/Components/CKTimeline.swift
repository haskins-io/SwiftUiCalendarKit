//
//  CKTimeline.swift
//  
//
//  Created by Mark Haskins on 12/04/2024.
//

import SwiftUI

struct CKTimeline: View {

    @Environment(\.ckConfig)
    private var config

    static let hourHeight = 60.0

    var body: some View {

        VStack(alignment: .leading, spacing: 0) {

            ForEach(0..<24) { hour in

                ZStack {
                    Rectangle()
                        .fill(isOutOfHours(hour: hour) ? Color.gray.opacity(0.1) : Color.clear)
                        .frame(height: CKTimeline.hourHeight)
                        .offset(x: 0, y: 30)

                    HStack {
                        Text(timelineconfiguration(hour: hour))
                            .font(.caption)
                            .frame(width: frameWidth(), alignment: .trailing)
                        Color.gray
                            .frame(height: 1)
                    }
                    .frame(height: CKTimeline.hourHeight)
                }
            }
        }
    }

    private func timelineconfiguration(hour: Int) -> String {

        if config.timeFormat24hr {
            if config.showMinutes {
                return String(format: "%02d:00", hour)
            } else {
                return String(format: "%02d", hour)
            }
        } else {
            if hour < 13 {
                return "\(hour)am"
            } else {
                let pmHour = hour - 12
                return "\(pmHour)pm"
            }
        }
    }

    private func frameWidth() -> CGFloat {
        if config.timeFormat24hr {
            if config.showMinutes {
                return 35
            } else {
                return 20
            }
        } else {
            return 35
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
        .workingHours(start: 9, end: 17)
}

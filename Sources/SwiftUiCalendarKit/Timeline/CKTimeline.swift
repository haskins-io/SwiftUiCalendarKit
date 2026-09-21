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

    @Environment(\.colorScheme)
    private var colorScheme

    nonisolated static let hourHeight = 60.0

    var showTime: Bool = true

    var normalColour: Color {
        colorScheme == .dark ? Color.black : Color.white
    }

    var body: some View {

        VStack(alignment: .leading, spacing: 0) {

            ForEach(0..<24) { hour in

                ZStack {
                    Rectangle()
                        .fill(isOutOfHours(hour: hour) ? Color.gray.opacity(0.1) : normalColour)
                        .overlay(
                            Rectangle()
                                .frame(width: 1, height: nil, alignment: .trailing)
                                .foregroundColor(Color.gray), alignment: .trailing)
                        .frame(height: CKTimeline.hourHeight)
                        .offset(x: 0, y: 30)

                    HStack {
                        if showTime {
                            // `.caption` scales with Dynamic Type, so a fixed-width frame is a
                            // guarantee that it will wrap at some accessibility size — "00:00"
                            // came back as "00:0 / 0" on an iPad. `fixedSize` lets the label take
                            // the width it needs; the frame is a floor, not a cage.
                            Text(String(format: "%02d:00", hour))
                                .font(.caption)
                                .monospacedDigit()
                                .lineLimit(1)
                                .fixedSize(horizontal: true, vertical: false)
                                .frame(minWidth: 35, alignment: .trailing)
                        }

                        Color.gray
                            .frame(height: 1)
                    }
                    .frame(height: CKTimeline.hourHeight)
                }
            }
        }
    }
}

extension CKTimeline {

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


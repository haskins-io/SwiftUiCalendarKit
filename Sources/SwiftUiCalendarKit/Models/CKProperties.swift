//
//  File.swift
//  SwiftUiCalendarKit
//
//  Created by Mark Haskins on 30/12/2025.
//

import SwiftUI

public struct CKProperties {

    public var headingAligment: HorizontalAlignment

    public var timelineStartHour: Int
    public var timelineEndHour: Int

    public var showTimelineTime: Bool

    public init(
        headingAliignment: HorizontalAlignment = .leading,
        timelineStartHour: Int = 0,
        timelineEndHour: Int = 24,
        showTimelineTime: Bool = true,
    ) {
        self.headingAligment = headingAliignment

        if timelineStartHour > timelineEndHour {
            self.timelineStartHour = 0
            self.timelineEndHour = 24
        } else {

            if (timelineStartHour-2) >= 0  {
                self.timelineStartHour = (timelineStartHour - 2)
            } else {
                self.timelineStartHour = timelineStartHour
            }

            if (timelineEndHour + 2) <= 24 {
                self.timelineEndHour = (timelineEndHour + 2)
            } else {
                self.timelineEndHour = timelineEndHour
            }
        }

        self.showTimelineTime = showTimelineTime
    }
}

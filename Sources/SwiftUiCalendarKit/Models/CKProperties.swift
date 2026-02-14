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
        timelineStartHour: Int = 9,
        timelineEndHour: Int = 17,
        showTimelineTime: Bool = true,
    ) {
        self.headingAligment = headingAliignment

        if timelineStartHour > timelineEndHour {
            self.timelineStartHour = 9
            self.timelineEndHour = 17
        } else {
            self.timelineStartHour = timelineStartHour
            self.timelineEndHour = timelineEndHour
        }

        self.showTimelineTime = showTimelineTime
    }
}

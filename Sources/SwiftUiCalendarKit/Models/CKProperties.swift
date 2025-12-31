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

    public init() {
        self.headingAligment = .leading

        self.timelineStartHour = 0
        self.timelineEndHour = 24
    }

    public init(headingAligment: HorizontalAlignment = .leading) {
        self.headingAligment = headingAligment

        self.timelineStartHour = 0
        self.timelineEndHour = 24
    }

    public init(startHour: Int, endHour: Int) {
        self.headingAligment = .leading

        if startHour > endHour {
            self.timelineStartHour = 0
            self.timelineEndHour = 24
        } else {

            if (startHour-2) >= 0  {
                self.timelineStartHour = (startHour - 2)
            } else {
                self.timelineStartHour = startHour
            }

            if (endHour + 2) <= 24 {
                self.timelineEndHour = (endHour + 2)
            } else {
                self.timelineEndHour = endHour
            }
        }
    }
}

//
//  File.swift
//  
//
//  Created by Mark Haskins on 12/04/2024.
//

import SwiftUI

public struct CKEvent: CKEventSchema {

    public typealias Id = UUID
    public var id : Id = UUID()

    public var anyHashableID: AnyHashable { AnyHashable(id) }

    public var startDate = Date()
    public var endDate = Date()

    public var text = "Demo"
    public var primaryText = "primary"
    public var secondaryText = "secondary"

    public var backgroundColor = "#ffffff"

    public var showTotalTime = false

    public init(
        startDate: Date,
        endDate: Date,
        text: String,
        primaryText: String = "",
        secondaryText: String = "",
        backCol: String = "#ffffff"
    ) {
        self.startDate = startDate
        self.endDate = endDate

        self.text = text
        self.primaryText = primaryText
        self.secondaryText = secondaryText

        self.backgroundColor = backCol
    }

    public func backgroundAsColor() -> Color {
        return Color(hex: backgroundColor) ?? Color.white
    }

    public func totalTime() -> String {
        let components = Calendar.current.dateComponents([.hour, .minute], from: startDate, to: endDate)
        if let hours = components.hour, let minutes = components.minute {
            return ("\(hours)h, \(minutes)m")
        }
        return ""
    }
}

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

    public var backgroundColor = "#ffffff"

    public init(
        startDate: Date,
        endDate: Date,
        text: String,
        backCol: String = "#ffffff"
    ) {
        self.startDate = startDate
        self.endDate = endDate
        self.text = text

        self.backgroundColor = backCol
    }

    public func backgroundAsColor() -> Color {
        return Color(hex: backgroundColor) ?? Color.white
    }
}

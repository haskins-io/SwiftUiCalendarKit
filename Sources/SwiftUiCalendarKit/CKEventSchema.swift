//
//  Event.swift
//  SwiftUiCalendars
//
//  Created by Mark Haskins on 11/04/2024.
//

import SwiftUI

public protocol CKEventSchema: Identifiable {

    var anyHashableID: AnyHashable { get }

    var startDate: Date  {get set}
    var endDate: Date  {get set}

    var text: String  {get set}

    var font: String  {get set}

    var textColor: String  {get set}
    var backgroundColor: String  {get set}

    func textAsColor() -> Color
    func backgroundAsColor() -> Color
}

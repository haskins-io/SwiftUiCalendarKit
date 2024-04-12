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

    var font : Font {get}

    var textColor: Color {get}
    var backgroundColor: Color {get}
}

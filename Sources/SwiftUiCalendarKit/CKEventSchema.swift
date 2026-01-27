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
    var primaryText: String  {get set}
    var secondaryText: String  {get set}

    var backgroundColor: String  {get set}

    var showTotalTime: Bool {get  set}

    func backgroundAsColor() -> Color
    func totalTime() -> String}

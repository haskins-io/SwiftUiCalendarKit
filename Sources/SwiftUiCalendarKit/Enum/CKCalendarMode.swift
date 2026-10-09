//
//  CKCalendarMode.swift
//
//  Created by Mark Haskins on 11/04/2024.
//

import SwiftUI

public enum CKCalendarMode: String, CaseIterable, Identifiable {
    public var id: Self { self }
    case day
    case week
    case month
}

extension CKCalendarMode {

    /// The mode's name in `CKCalendarPicker`, from the package's string catalog.
    var label: LocalizedStringResource {
        CKStrings.mode(self)
    }
}

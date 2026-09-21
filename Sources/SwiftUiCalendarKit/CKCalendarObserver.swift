//
//  CKCalendarObserver.swift
//  
//
//  Created by Mark Haskins on 13/04/2024.
//

import SwiftUI

@Observable
class CKCalendarObserver {

    /// The event the reader last tapped, or `nil` for nothing selected.
    var event: CKEvent?
    var events: [CKEvent]?

    init() { }
}

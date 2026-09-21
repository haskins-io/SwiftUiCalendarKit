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
    ///
    /// §3.6: this used to be non-optional and default to a dummy `CKEvent`, so "nothing
    /// selected" was represented by a real-looking empty event and a second `eventSelected`
    /// flag had to be kept in agreement with it. An optional says it once and cannot disagree
    /// with itself.
    var event: CKEvent?
    var events: [CKEvent]?

    init() { }
}

//
//  CKCalendarObserver.swift
//  
//
//  Created by Mark Haskins on 13/04/2024.
//

import SwiftUI

@Observable
public class CKCalendarObserver {

    /// The event the reader last tapped, or `nil` for nothing selected.
    public var event: CKEvent?
    public var events: [CKEvent]?

    public init() { }
}

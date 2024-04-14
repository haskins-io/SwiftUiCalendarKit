//
//  File.swift
//  
//
//  Created by Mark Haskins on 13/04/2024.
//

import SwiftUI

public class CKCalendarObserver: ObservableObject {

    @Published public var event: any CKEventSchema = CKEvent(startDate: Date(), endDate: Date(), text: "")
    @Published public var eventSelected = false

    public init() {
        
    }
}

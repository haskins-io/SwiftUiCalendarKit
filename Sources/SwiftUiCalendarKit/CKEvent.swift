//
//  File.swift
//  
//
//  Created by Mark Haskins on 12/04/2024.
//

import SwiftUI

struct CKEvent: CKEventSchema {
    
    typealias Id = UUID
    var id : Id = UUID()

    var anyHashableID: AnyHashable { AnyHashable(id) }

    var startDate = Date()
    var endDate = Date()

    var text = "Demo"

    var font = ""
    var textColor = "#000000"
    var backgroundColor = "#ffffff"

}

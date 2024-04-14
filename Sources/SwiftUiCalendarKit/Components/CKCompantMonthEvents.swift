//
//  File.swift
//  
//
//  Created by Mark Haskins on 14/04/2024.
//

import SwiftUI

struct CKCompantMonthEvents: View {

    private var events: [any CKEventSchema]

    init(events: [any CKEventSchema]) {
        self.events = events
    }

    var body: some View {

        List {
            ForEach(events, id: \.anyHashableID) { event in
                Text(event.text)
            }
        }
    }
}

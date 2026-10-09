//
//  CKTimeIndicator.swift
//
//  Created by Mark Haskins on 13/02/2026.
//

import SwiftUI

struct CKTimeIndicator: View {

    @Environment(\.locale)
    private var locale

    var date: Date?
    var time: Date
    var showTime: Bool = true

    var body: some View {
        HStack(spacing: 0) {
            if showTime {
                Text(time.formatted(.dateTime.hour().minute().locale(self.locale)))
                    .font(.caption)
                    .padding(.leading, 7)
                    .foregroundStyle(Color.red)
            }

            VStack {
                if let theDate = date {
                    if Calendar.current.isDate(theDate, inSameDayAs: Date()) {
                        Divider().frame(height: 2).overlay(.red)
                    } else {
                        Divider().frame(height: 2).overlay(.red.opacity(0.3))
                    }
                } else {
                    Divider().frame(height: 2).overlay(.red.opacity(0.3))
                }
            }
            .padding(0)
        }
    }
}

#Preview {
    CKTimeIndicator(
        time: Date()
    )
}

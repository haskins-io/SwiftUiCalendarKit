//
//  CKWeekdayLabel.swift
//  SwiftUiCalendarKit
//
//  Created by Mark Haskins on 09/10/2026.
//

import SwiftUI

/// A day header's weekday name: the longest of the locale's names that fits the column.
///
/// "Wed" in English, but Arabic's abbreviated name is the full word, so a narrow column falls
/// back to the short or narrow name instead of truncating. See `CKFormat.weekdaySymbols`.
struct CKWeekdayLabel: View {

    let date: Date

    var body: some View {
        ViewThatFits(in: .horizontal) {
            ForEach(CKFormat.weekdaySymbols(self.date), id: \.self) { symbol in
                Text(symbol)
                    .lineLimit(1)
            }
        }
    }
}

#Preview {
    HStack {
        CKWeekdayLabel(date: Date())
            .frame(width: 80)
            .border(.gray)

        CKWeekdayLabel(date: Date())
            .frame(width: 20)
            .border(.gray)
    }
}

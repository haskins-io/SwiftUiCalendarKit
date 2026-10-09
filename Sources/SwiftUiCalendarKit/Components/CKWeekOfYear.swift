//
//  SwiftUIView.swift
//  SwiftUiCalendarKit
//
//  Created by Mark Haskins on 17/02/2026.
//

import SwiftUI

struct CKWeekOfYear: View {

    @Environment(\.locale)
    private var locale

    @Environment(\.ckConfig)
    private var config

    private let calendar = Calendar.current

    var date: Date

    var body: some View {

        if config.showWeekNumber && calendar.weekOfYear(currentDate: date) != -1 {

            Text(CKStrings.weekNumber(calendar.weekOfYear(currentDate: date)).locale(self.locale))
                .padding([.trailing, .leading], 10)
                .font(.footnote)
                .foregroundStyle(Color.gray.opacity(0.75))
        }
    }
}

#Preview {
    CKWeekOfYear(date: Date())
        .showWeekNumbers(true)
}

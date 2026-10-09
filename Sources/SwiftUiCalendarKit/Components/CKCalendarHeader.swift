//
//  CKCalendarHeader.swift
//
//  Created by Mark Haskins on 11/04/2024.
//

import SwiftUI

struct CKCalendarHeader: View {

    @Environment(\.locale)
    private var locale

    @Environment(\.calendar)
    private var calendar

    /// Dates as the reader's locale and calendar write them.
    private var dateStyle: Date.FormatStyle {
        .dateTime.locale(self.locale).calendar(self.calendar)
    }

    @Binding var currentDate: Date

    var addWeek: Bool

    var body: some View {

        HStack {

            HStack {
                Text(currentDate.formatted(self.dateStyle.month(.wide).year()))
            }
            .padding(.leading, 20)
            .padding(.top, 5)
            .font(.title)

            Spacer()

            CKDateStepper(date: $currentDate, component: addWeek ? .weekOfYear : .month)
                .padding(.trailing, 30)
                .padding(.top, 5)
        }
    }
}

#Preview {
    CKCalendarHeader(
        currentDate: .constant(Date()),
        addWeek: false
    )
}

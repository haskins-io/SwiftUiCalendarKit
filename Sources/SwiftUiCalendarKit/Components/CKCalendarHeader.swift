//
//  CKCalendarHeader.swift
//
//  Created by Mark Haskins on 11/04/2024.
//

import SwiftUI

struct CKCalendarHeader: View {

    @Binding var currentDate: Date
    var addWeek: Bool

    var body: some View {

        HStack {

            HStack {
                Text(currentDate.formatted(.dateTime.month(.wide)))
                    .bold()
                Text(currentDate.formatted(.dateTime.year()))
            }
            .padding(.leading, 20)
            .padding(.top, 5)
            .font(.title)

            Spacer()

            HStack(spacing: 1) {

                Button {
                    guard let newDate = Calendar.current.date(
                        byAdding: addWeek ? .weekOfYear : .month,
                        value: -1,
                        to: currentDate
                    ) else {
                        return
                    }
                    currentDate = newDate
                } label: {
                    Image(systemName: "chevron.left")
                }

                Button {
                    currentDate = Date.now
                } label: {
                    Text("Today")
                }

                Button {
                    guard let newDate = Calendar.current.date(
                        byAdding: addWeek ? .weekOfYear : .month,
                        value: 1,
                        to: currentDate
                    ) else {
                        return
                    }
                    currentDate = newDate
                } label: {
                    Image(systemName: "chevron.right")
                }
            }
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

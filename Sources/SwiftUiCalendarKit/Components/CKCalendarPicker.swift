//
//  CalendarPicker.swift
//  freya
//
//  Created by Mark Haskins on 09/04/2024.
//

import SwiftUI

struct CKCalendarPicker: View {

    @Binding var mode: CKCalendarMode

    var body: some View {
        Picker("Display Mode", selection: $mode) {
            ForEach(CKCalendarMode.allCases) { calendarMode in
                Text(calendarMode.label)
            }
        }
        .pickerStyle(SegmentedPickerStyle())
    }
}

#Preview {
    CKCalendarPicker(mode: .constant(CKCalendarMode.day))
}

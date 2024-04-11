//
//  CalendarPicker.swift
//  freya
//
//  Created by Mark Haskins on 09/04/2024.
//

import SwiftUI

struct CalendarPicker: View {

    @Binding var mode: CalendarMode

    var body: some View {
        Picker("Display Mode", selection: $mode) {
            ForEach(CalendarMode.allCases) { calendarMode in
                Text(calendarMode.label)
            }
        }
        .pickerStyle(SegmentedPickerStyle())
    }
}

#Preview {
    CalendarPicker(mode: .constant(CalendarMode.day))
}

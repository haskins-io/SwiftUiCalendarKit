//
//  CKCalendarPicker.swift
//
//  Created by Mark Haskins on 09/04/2024.
//

import SwiftUI

public struct CKCalendarPicker: View {

    @Environment(\.locale)
    private var locale

    @Binding private var mode: CKCalendarMode

    public init(mode: Binding<CKCalendarMode>) {
        self._mode = mode
    }

    public var body: some View {
        Picker(selection: $mode) {
            ForEach(CKCalendarMode.allCases) { calendarMode in
                Text(calendarMode.label.locale(self.locale))
            }
        } label: {
            Text(CKStrings.displayMode.locale(self.locale))
        }
        .pickerStyle(SegmentedPickerStyle())
    }
}

#Preview {
    CKCalendarPicker(
        mode: .constant(CKCalendarMode.day)
    )
}

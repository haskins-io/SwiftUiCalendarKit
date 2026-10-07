//
//  File.swift
//  SwiftUiCalendarKit
//
//  Created by Mark Haskins on 21/09/2026.
//

import SwiftUI

struct CKAgendaToday: View {

    @Binding var scrollRequest: Int

    var body: some View {
        HStack {
            Spacer()
            Button {
                withAnimation {
                    scrollRequest += 1
                }
            } label: {
                Image(systemName: "clock.circle")
            }
            .padding(.horizontal)
        }
        .font(.title)
    }
}

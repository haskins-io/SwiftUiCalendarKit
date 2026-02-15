//
//  SwiftUIView.swift
//  SwiftUiCalendarKit
//
//  Created by Mark Haskins on 13/02/2026.
//

import SwiftUI

struct CKTimeIndicator: View {

    var time: Date

    var body: some View {
        HStack {

            Text(time.formatted(.dateTime.hour().minute()))
                .font(.caption)
                .padding(.leading, 7)
                .foregroundStyle(Color.red)

            VStack { }
                .frame(maxWidth: .infinity, minHeight: 2, maxHeight: 2, alignment: .leading)
                .background(Color.red.opacity(0.3))
        }
    }
}

#Preview {
    CKTimeIndicator(time: Date())
}

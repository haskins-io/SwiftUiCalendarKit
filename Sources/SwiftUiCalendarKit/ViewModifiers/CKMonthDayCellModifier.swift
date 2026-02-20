//
//  SwiftUIView.swift
//  SwiftUiCalendarKit
//
//  Created by Mark Haskins on 20/02/2026.
//

import SwiftUI

struct CKMonthDayCellModifier: ViewModifier {

    func body(content: Content) -> some View {
        content
            .overlay(Rectangle().frame(width: 1, height: nil, alignment: .trailing)
                .foregroundColor(Color.gray.opacity(0.5)), alignment: .trailing)
            .overlay(Rectangle().frame(width: nil, height: 1, alignment: .bottom)
                .foregroundColor(Color.gray.opacity(0.5)), alignment: .bottom)
    }
}

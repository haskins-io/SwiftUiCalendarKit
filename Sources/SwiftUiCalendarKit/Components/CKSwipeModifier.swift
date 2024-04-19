//
//  SwiftUIView.swift
//  
//
//  Created by Mark Haskins on 17/04/2024.
//

import SwiftUI

public struct CKSwipeModifier: ViewModifier {

    @Binding private var date: Date
    let component: Calendar.Component

    public init(date: Binding<Date>, component: Calendar.Component) {
        self._date = date
        self.component = component
    }

    private let calendar = Calendar(identifier: .gregorian)

    public func body(content: Content) -> some View {
        content
            .gesture(DragGesture(minimumDistance: 3.0, coordinateSpace: .local)
                .onEnded { value in
                    switch(value.translation.width, value.translation.height) {
                    case (...0, -30...30):
                        withAnimation {
                            date = changeDate(forward: true)
                        }

                    case (0..., -30...30):
                        withAnimation {
                            date = changeDate(forward: false)
                        }

                    default:  print("no clue")
                    }
                }
            )
    }

    private func changeDate(forward: Bool) -> Date {

        var val = 1
        if (!forward) {
            val = -1
        }

        guard let newDate = calendar.date(
            byAdding: component,
            value: val,
            to: date
        ) else {
            return date
        }

        return newDate
    }
}

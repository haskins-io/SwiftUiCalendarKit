//
//  File.swift
//  SwiftUiCalendarKit
//
//  Created by Mark Haskins on 23/09/2026.
//

import Foundation

enum ModelOneProviding: CKEventProviding {

    static func events(from model: ModelOne, in range: DateInterval) -> [CKEvent] {
        Self.events(from: model, in: range, asOf: Date())
    }

    static func events(from model: ModelOne, in range: DateInterval, asOf now: Date) -> [CKEvent] {

        guard range.contains(model.dueDate) else {
            return []
        }

        let overdue = model.dueDate < Date()

        return [
            CKEvent(
                kind: .deadline(model.dueDate),
                title: "Invoice \(model.invoiceNumber) \(overdue ? "overdue" : "due")",
                subtitle: "Chace Invoice",
                systemImage: model.icon,
                tint: overdue ? .red : .orange,
            )
        ]
    }
}

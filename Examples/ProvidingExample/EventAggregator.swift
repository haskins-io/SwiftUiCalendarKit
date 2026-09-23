//
//  File.swift
//  SwiftUiCalendarKit
//
//  Created by Mark Haskins on 23/09/2026.
//

import Foundation

/**
 
 */
@MainActor
struct EventAggregator {

    func events(in range: DateInterval, scope: CKEventScope = .overview) -> [CKEvent] {

        var events: [CKEvent] = []

        events += self.fetch(ModelOne.self).flatMap { ModelOneProviding.events(from: $0, in: range) }
        events += self.fetch(ModelTwo.self).flatMap { ModelTwoProviding.events(from: $0, in: range) }

        return events
            .sorted { $0.startDate < $1.startDate }
    }

    private func fetch<T: Model>(_ type: T.Type) -> [T] {
        // return all your models of the tyoe
    }
}

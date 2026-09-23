//
//  File.swift
//  SwiftUiCalendarKit
//
//  Created by Mark Haskins on 23/09/2026.
//

import Foundation

/// Maps one model to *zero or more* ``CKEvent``s for a visible date range.
protocol CKEventProviding {

    associatedtype Model

    static func events(from model: Model, in range: DateInterval) -> [CKEvent]
}

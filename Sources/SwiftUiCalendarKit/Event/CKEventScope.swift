//
//  File.swift
//  SwiftUiCalendarKit
//
//  Created by Mark Haskins on 21/09/2026.
//

import Foundation

/// How much detail a calendar surface can carry.
nonisolated enum CKEventScope: Hashable, Sendable {

    /// A month or week grid: the commitments and the deadlines, and nothing inside a day.
    case overview

    /// A single day, where sub-events are the reason the reader opened it.
    case day

    var includesSubEvents: Bool { self == .day }
}

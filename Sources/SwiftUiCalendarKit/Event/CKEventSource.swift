//
//  File.swift
//  SwiftUiCalendarKit
//
//  Created by Mark Haskins on 21/09/2026.
//

import Foundation

/// Where an event came from, so a tap can go back to it.
nonisolated enum CKEventSource: Hashable, Sendable {

    case eventSource(UUID)

}

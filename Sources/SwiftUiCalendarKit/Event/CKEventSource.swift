//
//  File.swift
//  SwiftUiCalendarKit
//
//  Created by Mark Haskins on 21/09/2026.
//

import Foundation

/// Where an event came from, so a tap can go back to it.
public nonisolated enum CKEventSource: Hashable, Sendable {

    case event(UUID)

}

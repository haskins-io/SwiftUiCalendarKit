//
//  File.swift
//  SwiftUiCalendarKit
//
//  Created by Mark Haskins on 14/02/2026.
//

import SwiftUI

struct CKConfig: Equatable {

    // general properties
    var currentDayColour = Color.red

    var headingAlignment: HorizontalAlignment = .leading

    // Timeline Settings
    var dayStart: Int = 0
    var dayEnd: Int = 24
    var showTime: Bool = false
}

private struct CKConfigKey: EnvironmentKey {
    static let defaultValue = CKConfig()
}

extension EnvironmentValues {
    var ckConfig: CKConfig {
        get { self[CKConfigKey.self] }
        set { self[CKConfigKey.self] = newValue }
    }
}

struct CKModifier: ViewModifier {

    @Environment(\.ckConfig) private var current

    let update: (inout CKConfig) -> Void

    func body(content: Content) -> some View {
        var next = current
        update(&next)

        return AnyView(content.environment(\.ckConfig, next))
    }
}

extension View {

    public func currentDayColour(_ value: Color) -> some View {
        transformEnvironment(\.ckConfig) { $0.currentDayColour = value }
    }

    public func showTime(_ value: Bool) -> some View {
        transformEnvironment(\.ckConfig) { $0.showTime = value }
    }

    public func headingAlignment(_ alignment: HorizontalAlignment) -> some View {
        transformEnvironment(\.ckConfig) { $0.headingAlignment = alignment }
    }

    public func workingHours(start: Int, end: Int) -> some View {
        transformEnvironment(\.ckConfig) {
            $0.dayStart = start
            $0.dayEnd = end
        }
    }
}

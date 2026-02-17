//
//  CKCalendarModifiers.swift
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
    var timeFormat24hr: Bool = false
    var showMinutes: Bool = false

    var showWeekNumber: Bool = false
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

    @Environment(\.ckConfig)
    private var current

    let update: (inout CKConfig) -> Void

    func body(content: Content) -> some View {
        var next = current
        update(&next)

        return AnyView(content.environment(\.ckConfig, next))
    }
}

extension View {

    /// When set changes the background colour of the curent date
    public func currentDayColour(_ value: Color) -> some View {
        transformEnvironment(\.ckConfig) { $0.currentDayColour = value }
    }

    /// When set shows a red line on a timeline to indicate the time
    public func showTime(_ value: Bool) -> some View {
        transformEnvironment(\.ckConfig) { $0.showTime = value }
    }

    /// When set the timeline timescale uses the 24hr clock 1 - 24. Default is 12hr clock 1pm, 2pm, etc
    public func timelineShows24hrClock(_ value: Bool) -> some View {
        transformEnvironment(\.ckConfig) { $0.timeFormat24hr = value }
    }

    /// When set the timeline time scale shows minutes, when you are using the 24hrs clock
    public func timelineShowsMinutes(_ value: Bool) -> some View {
        transformEnvironment(\.ckConfig) { $0.showMinutes = value }
    }

    /// When set the shows the week number in the header
    public func showWeekNumbers(_ value: Bool) -> some View {
        transformEnvironment(\.ckConfig) { $0.showWeekNumber = value }
    }

    public func headingAlignment(_ alignment: HorizontalAlignment) -> some View {
        transformEnvironment(\.ckConfig) { $0.headingAlignment = alignment }
    }

    /// Setting the working hours, will grey out the hours that are not worked on a Timeline calendar
    public func workingHours(start: Int, end: Int) -> some View {
        transformEnvironment(\.ckConfig) {
            $0.dayStart = start
            $0.dayEnd = end
        }
    }
}

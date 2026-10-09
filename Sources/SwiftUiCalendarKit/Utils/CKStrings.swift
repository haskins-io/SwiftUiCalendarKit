//
//  CKStrings.swift
//  SwiftUiCalendarKit
//
//  Created by Mark Haskins on 09/10/2026.
//

import Foundation

/// Every piece of text the package draws, looked up in its own string catalog
/// (`Resources/Localizable.xcstrings`).
///
/// A bare `Text("All Day")` looks in the *app's* bundle, so a string written that way in a
/// package is never translated. Views take their text from here instead, as a
/// `LocalizedStringResource` that points at the package's bundle. `Text` resolves it against the
/// environment's locale, and tests resolve it with `String(localized:)`.
///
/// The English text is the key, as Xcode extracts it. Changing the wording therefore changes the
/// key, and translations of the old key must be moved across in the catalog.
nonisolated enum CKStrings {

    // MARK: Event times

    /// The time column of an all-day event in `CKAgenda`.
    static var agendaAllDay: LocalizedStringResource {
        Self.resource("All Day", comment: "Agenda: the time column for an all-day event.")
    }

    /// The narrow time column of an all-day event in `CKCompactAgenda`.
    static var compactAgendaAllDay: LocalizedStringResource {
        Self.resource("All-Day", comment: "Compact agenda: the narrow time column for an all-day event.")
    }

    /// The time line of an all-day event in `CKListEventView`.
    static var listAllDay: LocalizedStringResource {
        Self.resource("All day", comment: "Event list row: the time column for an all-day event.")
    }

    /// A deadline, given the already-formatted time it is due.
    static func due(_ time: String) -> LocalizedStringResource {
        Self.resource(
            "Due \(time)",
            comment: "Agenda and event list: a deadline. The argument is the time it is due, e.g. 09:00."
        )
    }

    /// A deadline in `CKCompactAgenda`'s narrow column: the time, and "due" on the line below.
    ///
    /// One string rather than two stacked labels, so a translation can put the word before the
    /// time. The time is attributed so the view can style it apart from the word.
    static func compactDue(_ time: AttributedString) -> LocalizedStringResource {
        Self.resource(
            "\(time)\ndue",
            comment: "Compact agenda: a deadline, on two lines. The argument is the time, e.g. 09:00."
        )
    }

    /// When a multi-day event ends, given the already-formatted day.
    static func ends(_ day: String) -> LocalizedStringResource {
        Self.resource(
            "Ends \(day)",
            comment: "Agenda: a multi-day event. The argument is the day and month it ends, e.g. 16 Oct."
        )
    }

    /// The time column of a multi-day event in `CKAgenda`, given the already-formatted last day.
    static func until(_ day: String) -> LocalizedStringResource {
        Self.resource(
            "Until \(day)",
            comment: "Agenda: the time column for a multi-day event. The argument is its last day, e.g. 16 Oct."
        )
    }

    /// A multi-day event in `CKCompactAgenda`'s narrow column: "to", and its last day below.
    ///
    /// One string for the same reason as `compactDue`.
    static func compactUntil(_ day: AttributedString) -> LocalizedStringResource {
        Self.resource(
            "to\n\(day)",
            comment: "Compact agenda: a multi-day event, on two lines. The argument is its last day, e.g. 16 Oct."
        )
    }

    // MARK: Month and week

    /// The note under a month cell's chips when `count` events do not fit.
    static func moreEvents(_ count: Int) -> LocalizedStringResource {
        Self.resource(
            "+ \(count) more",
            comment: "Month cell: shown under the chips when some events do not fit. The argument is how many."
        )
    }

    /// The week number shown beside a date header.
    static func weekNumber(_ week: Int) -> LocalizedStringResource {
        Self.resource(
            "Week \(week)",
            comment: "Week number shown beside a date header. The argument is the week of the year."
        )
    }

    // MARK: Navigation

    /// The compact month's back button, read by VoiceOver.
    static var previous: LocalizedStringResource {
        Self.resource("Previous", comment: "Compact month: button that moves to the previous month, read by VoiceOver.")
    }

    /// The compact month's forward button, read by VoiceOver.
    static var next: LocalizedStringResource {
        Self.resource("Next", comment: "Compact month: button that moves to the next month, read by VoiceOver.")
    }

    /// The date stepper's back button, by what one press moves.
    static func previous(_ component: Calendar.Component) -> LocalizedStringResource {
        switch component {
        case .day:
            Self.resource(
                "Previous day",
                comment: "Date stepper: accessibility label for the back button when stepping by day."
            )

        case .weekOfYear:
            Self.resource(
                "Previous week",
                comment: "Date stepper: accessibility label for the back button when stepping by week."
            )

        default:
            Self.resource(
                "Previous month",
                comment: "Date stepper: accessibility label for the back button when stepping by month."
            )
        }
    }

    /// The date stepper's forward button, by what one press moves.
    static func next(_ component: Calendar.Component) -> LocalizedStringResource {
        switch component {
        case .day:
            Self.resource(
                "Next day",
                comment: "Date stepper: accessibility label for the forward button when stepping by day."
            )

        case .weekOfYear:
            Self.resource(
                "Next week",
                comment: "Date stepper: accessibility label for the forward button when stepping by week."
            )

        default:
            Self.resource(
                "Next month",
                comment: "Date stepper: accessibility label for the forward button when stepping by month."
            )
        }
    }

    // MARK: Calendar mode

    /// The calendar mode picker's title, read by VoiceOver.
    static var displayMode: LocalizedStringResource {
        Self.resource("Display Mode", comment: "Calendar mode picker: the picker's title, read by VoiceOver.")
    }

    /// A calendar mode's name in the picker.
    static func mode(_ mode: CKCalendarMode) -> LocalizedStringResource {
        switch mode {
        case .day:
            Self.resource("Day", comment: "Calendar mode picker: show one day.")

        case .week:
            Self.resource("Week", comment: "Calendar mode picker: show one week.")

        case .month:
            Self.resource("Month", comment: "Calendar mode picker: show one month.")
        }
    }

    // MARK: Lookup

    /// The package's resource bundle, which the compiled catalog is built into.
    static let bundle: Bundle = .module

    /// A string from the package's catalog rather than the app's.
    private static func resource(
        _ keyAndValue: String.LocalizationValue,
        comment: StaticString
    ) -> LocalizedStringResource {
        LocalizedStringResource(keyAndValue, bundle: .atURL(Self.bundle.bundleURL), comment: comment)
    }
}

extension LocalizedStringResource {

    /// This string, looked up and its numbers formatted for `locale`.
    ///
    /// Views pass the SwiftUI environment's locale, as they do to every date format style, so
    /// `.environment(\.locale, …)` changes the package's words along with its dates.
    func locale(_ locale: Locale) -> LocalizedStringResource {
        var resource = self
        resource.locale = locale
        return resource
    }
}

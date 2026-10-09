// CKStringsTests.swift
//
// The package's own text — `CKStrings` and the string catalog behind it.

@testable import SwiftUiCalendarKit
import Foundation
import SwiftUI
import Testing

@Suite("Strings — the package's text comes from its own catalog")
struct CKStringsTests {

    /// Every string the package draws, with the English it read before it was localised.
    /// Arguments are fixed so the interpolated ones can be compared too.
    private static let english: [(LocalizedStringResource, String)] = [
        (CKStrings.agendaAllDay, "All Day"),
        (CKStrings.compactAgendaAllDay, "All-Day"),
        (CKStrings.listAllDay, "All day"),
        (CKStrings.due("09:00"), "Due 09:00"),
        (CKStrings.compactDue("09:00"), "09:00\ndue"),
        (CKStrings.ends("16 Oct"), "Ends 16 Oct"),
        (CKStrings.until("16 Oct"), "Until 16 Oct"),
        (CKStrings.compactUntil("16 Oct"), "to\n16 Oct"),
        (CKStrings.moreEvents(3), "+ 3 more"),
        (CKStrings.weekNumber(42), "Week 42"),
        (CKStrings.previous, "Previous"),
        (CKStrings.next, "Next"),
        (CKStrings.previous(.day), "Previous day"),
        (CKStrings.previous(.weekOfYear), "Previous week"),
        (CKStrings.previous(.month), "Previous month"),
        (CKStrings.next(.day), "Next day"),
        (CKStrings.next(.weekOfYear), "Next week"),
        (CKStrings.next(.month), "Next month"),
        (CKStrings.displayMode, "Display Mode"),
        (CKStrings.mode(.day), "Day"),
        (CKStrings.mode(.week), "Week"),
        (CKStrings.mode(.month), "Month")
    ]

    @Test("In English, every string reads exactly as it did before localisation")
    func englishIsUnchanged() {
        for (resource, expected) in Self.english {
            #expect(String(localized: resource) == expected, "key: \(resource.key)")
        }
    }

    @Test("The hidden-events note counts, singular or plural", arguments: [
        (0, "+ 0 more"),
        (1, "+ 1 more"),
        (2, "+ 2 more"),
        (12, "+ 12 more")
    ])
    func moreEventsPlural(count: Int, expected: String) {
        #expect(String(localized: CKStrings.moreEvents(count)) == expected)
    }

    @Test("Every string the code uses is in the catalog, and the catalog holds nothing else")
    func catalogMatchesCode() throws {
        let used = Set(Self.english.map(\.0.key))
        let catalogued = try Self.catalogKeys()

        #expect(used.subtracting(catalogued).isEmpty, "missing from the catalog")
        #expect(catalogued.subtracting(used).isEmpty, "in the catalog but never used")
    }

    @Test("Interpolated strings are keyed by their format, not their arguments")
    func interpolatedKeys() {
        #expect(CKStrings.due("09:00").key == "Due %@")
        #expect(CKStrings.moreEvents(3).key == "+ %lld more")
        #expect(CKStrings.weekNumber(42).key == "Week %lld")
        #expect(CKStrings.compactDue("09:00").key == "%@\ndue")
        #expect(CKStrings.compactUntil("16 Oct").key == "to\n%@")
    }

    @Test("A styled argument keeps its style once localised, and the words around it do not take it")
    func attributedArgumentKeepsStyle() throws {
        var day = AttributedString("16 Oct")
        day.font = .caption

        let resolved = AttributedString(localized: CKStrings.compactUntil(day))
        let range = try #require(resolved.range(of: "16 Oct"))
        let word = try #require(resolved.range(of: "to"))

        #expect(String(resolved.characters) == "to\n16 Oct")
        #expect(resolved[range].font == .caption)
        #expect(resolved[word].font == nil)
    }

    @Test("The catalog is compiled into the package's own bundle, not the app's")
    func catalogIsInPackageBundle() {
        #expect(CKStrings.bundle != Bundle.main)
        #expect(CKStrings.bundle.developmentLocalization == "en")
        #expect(CKStrings.bundle.localizations.contains("en"))
        #expect(
            CKStrings.bundle.url(
                forResource: "Localizable",
                withExtension: "stringsdict",
                subdirectory: nil,
                localization: "en"
            ) != nil
        )
    }

    /// The keys in `Resources/Localizable.xcstrings`, read from the source file.
    private static func catalogKeys() throws -> Set<String> {
        struct Catalog: Decodable {
            let strings: [String: IgnoredEntry]
        }

        struct IgnoredEntry: Decodable {}

        let url = URL(filePath: #filePath)
            .deletingLastPathComponent()
            .appending(path: "../../Sources/SwiftUiCalendarKit/Resources/Localizable.xcstrings")
            .standardized

        let catalog = try JSONDecoder().decode(Catalog.self, from: Data(contentsOf: url))

        return Set(catalog.strings.keys)
    }
}

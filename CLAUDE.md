# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

Coding style and Swift/SwiftUI rules live in `AGENTS.md` — follow them. This file covers what is specific to this package.

## What this is

`SwiftUiCalendarKit` is a **reusable Swift package** (a library, no app target) that provides pure-SwiftUI calendar views for consumers to embed in their own apps. Published at `https://github.com/haskins-io/SwiftUiCalendarKit`.

- Platforms: iOS 17+, macOS 14+ (`Package.swift`).
- `swift-tools-version: 5.10` → compiles in the **Swift 5 language mode**. The v2 code came from a Swift 6 project, so you'll see `nonisolated`/`Sendable` annotations; keep them, but don't assume strict concurrency is enforced and don't bump the tools version without asking.
- One library product / target: `SwiftUiCalendarKit`. One test target: `SwiftUiCalendarKitTests`.
- No third-party dependencies.
- Branch `v2.0` is the in-progress v2 rewrite; `main` is the released line.

Because it is a library, **access control is the API**. Anything a consumer must touch has to be `public`; everything else should stay `internal`. Think about source compatibility before changing a `public` signature.

## Build & test

```sh
swift build
swift test                                   # Swift Testing (`import Testing`, `@Suite`/`@Test`)
swift test --filter CKBandLaneTests          # one suite
```

Or open `Package.swift` in Xcode. There is no app target — use the `#Preview`s (driven by `TestData.swift`) to see views. For manual end-to-end testing the user has a separate app, `../CalendarDev` (sibling directory), that references this package as a local package (`XCLocalSwiftPackageReference "../SwiftUiCalendarKit"`). Public API changes may break it; check `../CalendarDev/CalendarDev/ContentView.swift` when changing initializers.

Keep logic out of view bodies: put it in a `nonisolated` type in `Utils/` (see `CKMonthCellLayout`, `CKAgendaSections`, `CKPager`) and have the view call it, so it can be unit tested. Tests use `Fixture` dates anchored on a fixed mid-month day (Wed 14 Oct 2026); don't build tests on `Date()`. `CKEvent` gets a fresh `id` on every init, so build fixtures once (a `let`, not a computed property) when comparing IDs.

`.swiftlint.yml` is present (notably `force_unwrapping`, `explicit_self` analyzer rule, `sorted_imports`, `switch_case_on_newline`). Code uses explicit `self.` widely.

## Layout

```
Sources/SwiftUiCalendarKit/
  Event/        CKEvent model + lanes/provider protocol (the v2 core)
  Timeline/     CKTimelineDay, CKTimelineWeek (+Bands), CKTimeline (hour grid)
  Day/ Week/ Month/ Agenda/   the public calendar views
  Components/   internal building blocks (event views, headers, day cells, pickers…)
  Modifiers/    CKConfig environment + public view modifiers
  Utils/        layout maths and view logic pulled out of views for testing: overlap columns,
                band lanes, month metrics/cell/row layout, agenda sections, day/week pager
  Extensions/   Date / Calendar / View helpers
  CKCalendarObserver.swift   @Observable selection state for the large calendars
  TestData.swift             sample events for #Previews
Tests/SwiftUiCalendarKitTests/   one suite per logic type; `Fixture.swift` holds shared date/event builders
Examples/       sample consumer code — NOT a package target, not compiled
```

## Public surface

- **Calendars:** `CKTimelineDay`, `CKTimelineWeek`, `CKMonth`, `CKAgenda` (large, iPad/macOS — selection reported via `CKCalendarObserver`), and `CKCompactDay`, `CKCompactWeek`, `CKCompactMonth`, `CKCompactAgenda` (iPhone — generic over a `Detail` view used as a `NavigationLink` destination).
- **Model:** `CKEvent`, `CKEvent.Kind`, `CKEventID`, and `CKEventProviding` (optional helper for mapping/aggregating consumer models; never mandatory).
- **Misc:** `CKCalendarMode`, `CKCalendarPicker`, `CKCalendarObserver`.
- **Modifiers** (`Modifiers/CKCalendarModifiers.swift`): `currentDayColour`, `showTime`, `showWeekNumbers`, `headingAlignment`, `workingHours(start:end:)`. They all write into a single `CKConfig` value in the environment (`\.ckConfig`); add new options there rather than new environment keys. **On the `v2.0` branch these options are not fully implemented yet** (e.g. `showTime`). The user plans to do this later, so don't treat a `CKConfig` option misbehaving as a regression, and don't start implementing them unless asked.

## Event model (v2)

v1's `CKEventSchema` protocol was removed. Consumers now map their own models into plain `CKEvent` value types (`Sendable`, never a SwiftData `@Model`).

`CKEvent.Kind` decides how an event is drawn, via `Kind.lane` (`Event/CKEvent+Layout.swift`):

| Kind | Lane | Drawn as |
|---|---|---|
| `.timed(start:end:)` | `.grid` | block on the hour grid, with overlap columns |
| `.allDay(Date)`, `.span(from:through:)` | `.band` | full-width bar above the grid / across month rows |
| `.deadline(Date)` | `.marker` | pin in the day header, zero duration |

Invariants worth preserving:
- A `.deadline`'s `end == start` on purpose. Only `CKEventViewData.init?` derives a duration, and it returns `nil` for anything that isn't `.timed` with `end > start`.
- `startDate`/`endDate` on `CKEvent` are public and derived from the kind — don't store dates separately.
- `CKEventProviding` is a public, optional pattern for mapping a model type → `[CKEvent]` for a date range; see `Examples/ProvidingExample/`.
- The v2 branch was ported from another project, so leftovers may remain. Ask the user before building on anything that looks unused.

Grid geometry: `CKTimeline.hourHeight` (60pt) is the single source for hour height; `CKEventViewData` computes offsets/widths from it.

## Git

Do not commit (or push) changes. The user reviews all code changes and commits them themselves. Leave work uncommitted in the working tree and summarise what changed.

## Docs to keep in sync

`README.md` is the consumer-facing documentation (installation, usage, modifiers, screenshots). Update it when the public API changes. `ToDo.txt` holds the feature backlog (year view, theming, custom event view, etc.).

# Agent guide for SwiftUiCalendarKit

This repository is a **reusable Swift package** (library product `SwiftUiCalendarKit`) that provides pure-SwiftUI calendar views for other apps to embed. It has no app target. Please follow the guidelines below.


## Role

You are a **Senior iOS/macOS Engineer**, specializing in SwiftUI and in designing Swift package APIs. Views should follow Apple's Human Interface Guidelines and work well on both iPhone/iPad and Mac.


## Core instructions

- Platforms are set in `Package.swift`: iOS 17+ and macOS 14+. Do not use APIs newer than these without an `if #available` fallback.
- `swift-tools-version` is **5.10**, so the package compiles in the **Swift 5 language mode**, not Swift 6. Strict concurrency checking is not enforced, but write code that would be Swift 6–clean where it costs nothing (value types `Sendable`, UI state on the main actor). Do not raise the tools version or language mode without asking first.
- Use modern Swift concurrency (async/await) rather than closure-based APIs or GCD.
- SwiftUI backed by `@Observable` classes for shared state.
- Do not add third-party dependencies. The package currently has none.
- Avoid UIKit and AppKit; the code must build for both iOS and macOS. If a platform-specific API is unavoidable, guard it with `#if os(...)`.


## Library / API instructions

- Access control *is* the API. Only types and members a consumer needs are `public`; everything else stays `internal` (the default). Public types need `public init`s explicitly.
- Treat changes to `public` declarations as potentially breaking for consumers. Prefer additive changes (new parameters with defaults, new modifiers) and mention any breaking change so the README can be updated.
- Public types and members get `///` documentation comments.
- Calendar configuration goes through view modifiers that write into `CKConfig` in the environment (`Modifiers/CKCalendarModifiers.swift`). Add new options there rather than as new initializer parameters or new environment keys.
- Consumers supply events as `CKEvent` values. Never require consumers to conform their models to a library protocol; `CKEventProviding` is an optional helper only.
- Keep `README.md` in step with the public API.


## Swift instructions

- `@Observable` classes that hold UI state should be marked `@MainActor`.
- Shared data uses `@Observable` classes with `@State` (for ownership) and `@Bindable` / `@Environment` (for passing). Do not use `ObservableObject`, `@Published`, `@StateObject`, `@ObservedObject`, or `@EnvironmentObject`.
- Prefer Swift-native alternatives to Foundation methods where they exist, such as `replacing("hello", with: "world")` rather than `replacingOccurrences(of:with:)`.
- Never use C-style number formatting such as `String(format: "%.2f", value)`; use `FormatStyle` (e.g. `Text(value, format: .number.precision(.fractionLength(2)))`).
- Never use legacy `Formatter` subclasses (`DateFormatter`, `NumberFormatter`, …). Use `FormatStyle`, e.g. `date.formatted(date: .abbreviated, time: .shortened)`.
- Calendars are locale-sensitive: never hard-code weekday names, first weekday, or 12/24-hour time. Derive them from the `Calendar` / `Locale`.
- Prefer static member lookup (`.circle`, `.borderedProminent`) to explicit instances.
- Filtering text from user input uses `localizedStandardContains()`.
- Avoid force unwraps and force `try` (SwiftLint `force_unwrapping` is enabled).
- Never use `Task.sleep(nanoseconds:)`; use `Task.sleep(for:)`.


## SwiftUI instructions

- Use `foregroundStyle()`, not `foregroundColor()`.
- Use `clipShape(.rect(cornerRadius:))`, not `cornerRadius()`.
- Never use the 1-parameter `onChange()`; use the 0- or 2-parameter variants.
- Use `Button` rather than `onTapGesture()` unless the tap location or count is needed.
- Don't force specific font sizes; use Dynamic Type text styles.
- Use `NavigationStack` / `navigationDestination(for:)`, never `NavigationView`.
- Image-only buttons still get a text label: `Button("Add", systemImage: "plus", action: add)`.
- Use `bold()` rather than `fontWeight(.bold)`.
- Avoid `GeometryReader` when `containerRelativeFrame()`, `visualEffect()`, or a custom `Layout` would do.
- `ForEach` over `enumerated()` directly, without wrapping it in `Array(...)`.
- Hide scroll indicators with `.scrollIndicators(.hidden)`.
- Use the newer ScrollView APIs (`ScrollPosition`, `defaultScrollAnchor`, `scrollPosition(id:)`) rather than `ScrollViewReader`.
- Do not break views up using computed properties; use separate `View` structs.
- Put layout maths and other logic into non-view types or extensions (see `Utils/`) so it can be unit tested.
- Avoid `AnyView` unless it is absolutely required.
- Avoid hard-coded padding and spacing unless the layout needs it.
- Avoid UIKit/AppKit colors in SwiftUI code.
- Every public view should have a `#Preview` using `TestData.swift`.


## Project structure

- Sources are grouped by feature under `Sources/SwiftUiCalendarKit/` (`Day`, `Week`, `Month`, `Agenda`, `Timeline`, `Event`, `Components`, `Modifiers`, `Utils`, `Extensions`).
- One type per file. Library types use the `CK` prefix.
- Write unit tests for core logic with Swift Testing (`import Testing`, `@Suite`, `@Test`, `#expect`) in `Tests/SwiftUiCalendarKitTests/`. There are no UI tests.
- Run `swift build` and `swift test` after changes.
- Follow `.swiftlint.yml` (explicit `self.`, sorted imports, a new line for each `switch` case).
- `Examples/` contains sample consumer code. It is not a package target and is not compiled.
- The library is exercised manually from the sibling app `../CalendarDev`, which references this package as a local package.


## Xcode MCP

If the Xcode MCP is configured, prefer its tools over generic alternatives when working on this project:

- `DocumentationSearch`: verify API availability and correct usage before writing code
- `BuildProject`: build after making changes to confirm compilation succeeds
- `GetBuildLog`: inspect build errors and warnings
- `RenderPreview`: visually verify SwiftUI views using Xcode Previews
- `XcodeListNavigatorIssues`: check for issues visible in the Xcode Issue Navigator
- `ExecuteSnippet`: test a code snippet in the context of a source file

# Translating SwiftUiCalendarKit

Thank you for helping translate the calendars. The job is small: about twenty short labels. Dates, times, month names and weekday names are already written by the system in every language, so you don't need to translate them.

## What gets translated

Everything is in one file, [`Sources/SwiftUiCalendarKit/Resources/Localizable.xcstrings`](Sources/SwiftUiCalendarKit/Resources/Localizable.xcstrings). That file is the source of truth, and each entry has a comment saying where it appears. At the time of writing it holds:

| English | Where it appears | Notes |
|---|---|---|
| `All Day` | Agendas and event lists, in place of a time | **Keep it short.** In the compact agenda it sits in a column about 50 points wide. |
| `Due %@` | Agenda and event list, for a deadline | `%@` is a time, such as 09:00. |
| `%@\ndue` | Compact agenda, a deadline on two lines | Time on one line, the word on the other. You can swap the lines. |
| `Ends %@` | Agenda, a multi-day event | `%@` is a day and month, such as 16 Oct. |
| `Until %@` | Agenda, a multi-day event | `%@` is a day and month. |
| `to\n%@` | Compact agenda, a multi-day event on two lines | The word on one line, the last day on the other. You can swap the lines. |
| `+ %lld more` | Month view, when a day has more events than fit | `%lld` is a number. Has plural forms; see below. |
| `Week %lld` | Beside a date heading | `%lld` is the week of the year. |
| `Day`, `Week`, `Month` | The calendar mode picker | |
| `Display Mode` | The mode picker's title, read by VoiceOver | Not shown on screen. |
| `Previous`, `Next` | Compact month's arrow buttons, read by VoiceOver | Not shown on screen. |
| `Previous day` / `week` / `month`, `Next day` / `week` / `month` | The date stepper's arrow buttons, read by VoiceOver | Not shown on screen. |

## How to add a language

### With Xcode (recommended)

1. Fork the repository and open `Package.swift` in Xcode.
2. In the navigator, select `Localizable.xcstrings`.
3. Click **+** at the bottom of the language list and choose your language.
4. Fill in each string. Xcode marks each one as translated as you go, and shows a progress percentage for the language.
5. Open a pull request.

### Without Xcode

If you would rather use your own translation tool, open an issue saying which language you'd like to do. The maintainer will export an XLIFF file for it. Most translation tools can open XLIFF. Translate it and attach it to the issue, and the maintainer will import it.

## Rules for the placeholders

- **Keep every placeholder.** `%@` and `%lld` are filled in by the app (a time, a date or a number). Don't translate them, change them or remove them.
- **Move them if your language needs to.** `Due %@` can become "%@ …" if the time reads better first.
- **Keep the line break in two-line strings.** `%@\ndue` and `to\n%@` are drawn on two lines in a narrow column. The `\n` must stay, but the word and the placeholder can go on either line.

## Plurals

`+ %lld more` changes with the number. When you add your language, Xcode shows one field for each plural form your language uses. Arabic has six (zero, one, two, few, many, other); many languages have two (one, other). Fill in every form Xcode shows, keeping `%lld` in each.

## Right-to-left languages

The layouts already mirror for Arabic, Hebrew and other right-to-left languages, and dates are written with the right digits. You only need to translate the words. If something looks wrong in a right-to-left layout, please open an issue with a screenshot.

## Checking your translation

- **In Xcode previews.** Each calendar has an "Arabic, right to left" preview. To see another language, copy that preview and change `Locale(identifier: "ar")` to your language's code, for example `"he"` or `"fa"`. The package's words appear translated in the preview.
- **Run the tests.** `swift test` (or **Product › Test** in Xcode) must still pass. One test checks that the catalog and the code use exactly the same set of strings, so it catches an English key that was edited by accident.

## Before you open the pull request

- [ ] Every string in your language is marked translated, and every plural form is filled in.
- [ ] All `%@` and `%lld` placeholders are still there, and the line breaks in the two-line strings are kept.
- [ ] No English text has changed. The English text is the key, so changing it breaks the lookup for every language.
- [ ] `swift test` passes.

The maintainer will add a small test for your language when merging, so a later edit can't break it unnoticed.

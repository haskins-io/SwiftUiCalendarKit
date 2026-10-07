# SwiftUiCalendarKit
A SwiftUi library that provides different Calendar formats that can be included in any SwiftUI application.
All the calendars are written purely in SwiftUI.

## Installation
1. Open your existing Xcode project or create a new one
2. Open the Swift Packages Manager
	- In the project navigator, select your project file to open the project settings.
	- Navigate to the the **Package Dependencies** tab
3. Add the SwiftUICalendarKit Package
	- Click the **+** button at the bottom of the tab
	- In the dialog box that appears, enter the URL for SwiftUiCalendarKit: `https://github.com/haskins-io/SwiftUiCalendarKit.git`
4. Specify version rules
	- Xcode will prompt you to specify version rules for the package. "Up to Next Major Version" ensures compatibility with future updates that don't introduce breaking changes.
	- Click **Add Package**
 
 The Main Branch will always have the latest functionality. It should be stable and usable. Reference a release if you want to pin the code until you have had a chance to test against the Main branch. 

# Release v2.0
Version 2 is a breaking change: **the `CKEventSchema` protocol has been removed**. See [Upgrading from v1](#upgrading-from-v1). Make sure you are pointing at the v1.0.1 release if you don't want to update your code.

## Requirements
- iOS 17+ / macOS 14+
- Swift 5.10+

## Usage
```swift
import SwiftUI
import SwiftUiCalendarKit

struct CalendarTest: View {

    private static let calendar = Calendar.current

    let events: [CKEvent] = [
        CKEvent(
            kind: .allDay(Date()),
            title: "Event 1",
            tint: .blue
        ),
        CKEvent(
            kind: .timed(
                start: calendar.date(bySettingHour: 12, minute: 0, second: 0, of: Date()) ?? Date(),
                end: calendar.date(bySettingHour: 12, minute: 30, second: 0, of: Date()) ?? Date()
            ),
            title: "Event 2",
            subtitle: "Meeting room 1",
            systemImage: "star",
            tint: .green,
            isTentative: true
        )
    ]

    @State private var date = Date()

    var body: some View {
        NavigationStack {
            CKCompactDay(
                detail: { event in EventDetail(event: event) },
                events: events,
                date: $date
            )
            .showTime(true)
            .workingHours(start: 7, end: 19)
            .currentDayColour(.blue)
        }
    }
}
```

## Events
Every calendar takes an array of `CKEvent` values. You create these from your own models however you like, so your models (including SwiftData `@Model` classes) don't need to conform to anything.

```swift
CKEvent(
    kind: CKEvent.Kind,       // what the event is, and so how it is drawn
    title: String,
    subtitle: String? = nil,
    systemImage: String = "", // an SF Symbol name, or empty for none
    tint: Color,
    isTentative: Bool = false // e.g. unconfirmed. Drawn hatched
)
```

The `kind` decides where an event appears:

| Kind | Drawn as |
|------|----------|
| `.timed(start:end:)` | A block on the hour grid. Overlapping events share the width. |
| `.allDay(Date)` | A bar across the top of that day. |
| `.span(from:through:)` | A bar spanning several days. |
| `.deadline(Date)` | A marker in the day header: a point in time with no duration. |

### Aggregating events with CKEventProviding (optional)
If your events come from several different model types, you can use `CKEventProviding` to keep the mapping from each model to `CKEvent`s in one place. A provider can return zero, one or many events for a model in the visible date range:

```swift
enum InvoiceProviding: CKEventProviding {

    static func events(from model: Invoice, in range: DateInterval) -> [CKEvent] {
        guard range.contains(model.dueDate) else { return [] }

        return [
            CKEvent(
                kind: .deadline(model.dueDate),
                title: "Invoice \(model.number) due",
                systemImage: "doc.text",
                tint: .orange
            )
        ]
    }
}
```

You don't have to use it. See `Examples/ProvidingExample` for a fuller example that aggregates two model types.

## Calendar Modifiers
These modifiers configure the calendars. They can be applied to the calendar or to any view that contains it.
### currentDayColour(_:)
Sets the highlight colour of the current date.
### showTime(_:)
Shows a red line on a timeline to indicate the current time.
### showWeekNumbers(_:)
Shows the week number in the header.
### headingAlignment(_:)
Sets the position of the heading on `CKCompactWeek`.
### workingHours(start:end:)
Sets the working hours of a timeline calendar. Hours outside them are shaded light grey.

## Calendars
| CKTimelineDay | CKTimelineWeek | CKMonth |
|---------------|----------------|---------|
| This shows all the events for a selected date. You can use this for MacOs and iPad. | This shows all the events for a selected week. You can use this for MacOs and iPad | This shows all the events for a selected month. You can use this for MacOs and iPad|
|<img src="https://github.com/haskins-io/SwiftUiCalendarKit/blob/main/Screenshots/CKTimelineDay.png" width="300"/>| <img src="https://github.com/Haskins-io/SwiftUiCalendarKit/blob/main/Screenshots/CKTimelineWeek.png" width="300"/>| <img src="https://github.com/Haskins-io/SwiftUiCalendarKit/blob/main/Screenshots/CKMonth.png" width="300"/> |
| CKCompactDay | CKCompactWeek | CKCompactMonth | CKCompactAgenda |
|---------------|----------------|---------|----------------------|
| This shows all the events for a selected date. Best used on an iPhone. Swiping Left or Right on the timeline will change the date.| This shows all the events for a selected week. This only shows a single timeline and you select the date you want from the top. Best used on an iPhone. Swiping Left or Right on the week will change it. | This shows all the events for a selected month. This shows a picker style calendar. Best used on an iPhone | On ordered list of events. Best used on an iPhone |
|<img src="https://github.com/haskins-io/SwiftUiCalendarKit/blob/main/Screenshots/CKCompactDay.png" width="300"/>| <img src="https://github.com/Haskins-io/SwiftUiCalendarKit/blob/main/Screenshots/CKCompactWeek.png" width="300"/>| <img src="https://github.com/haskins-io/SwiftUiCalendarKit/blob/main/Screenshots/CKCompactMonth.png" width="300"/>| <img src="https://github.com/haskins-io/SwiftUiCalendarKit/blob/main/Screenshots/CKCompactAgenda.png" width="300"/> |

## Examples
There is an example of how to use all the calendars in `/Examples`.
## Navigation
The compact calendars (`CKCompactDay`, `CKCompactWeek`, `CKCompactMonth` and `CKCompactAgenda`) take a `detail` view builder that gives your event detail view. It is used as the destination of a `NavigationLink`, so place the calendar inside a `NavigationStack`. See the Examples folder.

The larger calendars (`CKTimelineDay`, `CKTimelineWeek`, `CKMonth` and `CKAgenda`) take a `CKCalendarObserver`. When an event is clicked or tapped, the calendar sets `observer.event` to that event. On `CKMonth`, tapping "+ n more" on a day sets `observer.events` to all of that day's events. How your app responds is up to you, for example:

```swift
@State private var observer = CKCalendarObserver()

CKTimelineWeek(observer: observer, events: events, date: $date)
    .sheet(item: $observer.event) { event in
        EventDetail(event: event)
    }
```

## Upgrading from v1
v2 is a breaking change. **The `CKEventSchema` protocol has been removed.** Requiring your models to adopt a protocol was not a good fit, especially for SwiftData models, which had to gain properties they might never use. Instead, map your models to `CKEvent` values (optionally with `CKEventProviding`, see above).

The look and feel of the calendars has also been updated, with major improvements to the way events are rendered, including all-day, multi-day and deadline events.

## Things that I would like to add in the future
* Drag and drop events
* More customisations / Themes
* A year Calendar

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
 
 The Main Branch will always have the latest functionality. It should be stable and usable. Reference a release if you want to fix the code until, you have had a chance to test against the Main branch.
 

## Usage   
```
import SwiftUiCalendarKit

struct CalendarTest: View {

    let events: [any CKEventSchema] = [
        CKEvent(
            startDate: Date().dateFrom(09, 2, 2026, 12, 30),
            endDate: Date().dateFrom(09, 2, 2026, 13, 30),
            text: "Monday",
            backCol: "#D74D64"
        ),
        CKEvent(
            startDate: Date().dateFrom(10, 2, 2026, 12, 30),
            endDate: Date().dateFrom(10, 2, 2026, 13, 30),
            text: "Tuesday",
            backCol: "#D74D64"
        )
    ]
    
    @State private var date = Date()

    var body: some View {
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

```

## Calendar Modifiers
There are some modifiers that can be used to configure the calendars. These are:-

### currentDayColour
When set changes the background colour of the curent date

### showTime
When set shows a red line on a timeline to indicate the time

### timelineShows24hrClock
When set the timeline timescale uses the 24hr clock 1 - 24. Default is 12hr clock 1pm, 2pm, etc

### timelineShowsMinutes
When set the timeline time scale shows minutes, when you are using the 24hrs clock

### showWeekNumbers
When set the shows the week number in the header

### headingAlignment
Applying this changes the position of the heading on the CKCompactWeek

### workingHours
Applying this sets the working hours of a Timeline calendar. This will change the colour of the non working hours to be light grey.


## Calendars

| CKTimelineDay | CKTimelineWeek | CKMonth |
|---------------|----------------|---------|
| This shows all the events for a selected date. You can use this for MacOs and iPad. | This shows all the events for a selected week. You can use this for MacOs and iPad | This shows all the events for a selected month. You can use this for MacOs and iPad|
|<img src="https://github.com/haskins-io/SwiftUiCalendarKit/blob/main/Screenshots/CKTimelineDay.png" width="300"/>| <img src="https://github.com/Haskins-io/SwiftUiCalendarKit/blob/main/Screenshots/CKTimelineWeek.png" width="300"/>| <img src="https://github.com/Haskins-io/SwiftUiCalendarKit/blob/main/Screenshots/CKMonth.png" width="300"/> |


| CKCompactDay | CKCompactWeek | CKCompactMonth |
|---------------|----------------|---------|
| This shows all the events for a selected date. Best used on an iPhone. Swiping Left or Right on the timeline will change the date.| This shows all the events for a selected week. This only shows a single timeline and you select the date you want from the top. Best used on an iPhone. Swiping Left or Right on the week will change it. | This shows all the events for a selected month. This shows a picker style calendar. Best used on an iPhone|
|<img src="https://github.com/haskins-io/SwiftUiCalendarKit/blob/main/Screenshots/CKCompactDay.png" width="300"/>| <img src="https://github.com/Haskins-io/SwiftUiCalendarKit/blob/main/Screenshots/CKCompactWeek.png" width="300"/>| <img src="https://github.com/haskins-io/SwiftUiCalendarKit/blob/main/Screenshots/CKCompactMonth.png" width="300"/>|

## Examples
There is an example of how to use all the calendars in /Examples


## Events
There is a Protocal called CKEventSchema that defines what a Calendar entry should look like. There is an example implementation called 'CKEvent'. Though you can use your own classes/structs if you want and simply add a reference to the protocol.

## Navigation
For the Compact calendars you can pass in a View that provides your *EventDetail*. This is used as part of a NavigationLink and when tapping an Event it will navigate to the passed View. See in the Examples folder.

For the other calenders there is an CalendarObserver class. When you click/tap on an event it will set the event object that was tapped on the class and then set 'eventSelected' flag to be true. How you handle this is down to your application.


## FAQ
### Why are you using two dates to define an event, when you could be using a DateInterval.?
The simple answer is that I'm using this with SwiftData, and it doesn't support DateInterval as a data type. There might be a way around this, but I'm good with what I have at the moment.

### Why are you storing Colors as String?
Same answer as above. The Protocol does force you to implement functions to return Colors. How you implement them is up to you. The Color extension provides a function that converts a Hex string to a color. You might want to use this, or provide your own soluion.


## Known Issues
### Overlapping events
While the code can handle overlapping events, and display them correctly, there are some overlay scenarios which it doesn't handle very well.


## Things that I would like to add in the future
* MultiDay Events
* Drag and drop events
* More customisations / Themes
* A year Calendar

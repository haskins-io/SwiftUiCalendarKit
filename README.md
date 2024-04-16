
# SwiftUiCalendarKit

I'm developing this as part of an application that requires multiple calendar views, on different devices. This means at this time I'm trying to get the functionality that I need for my larger application working, and not spending too much time at this moment looking at localisation, customisations, etc. I'm sure I'll get around to those at some time, just not planned as yet.

All the calendars are written purely in SwiftUI.

What is on the master branch should work.

## Available Calendars
### CKTimelineDay

This shows all the events for a selected date. You can use this for MacOs and iPad

<img src="https://github.com/haskins-io/SwiftUiCalendarKit/blob/main/Screenshots/CKTimelineDay.png" width="300"/>

### CKTimelineWeek

This shows all the events for a selected week. You can use this for MacOs and iPad

<img src="https://github.com/Haskins-io/SwiftUiCalendarKit/blob/main/Screenshots/CKTimelineWeek.png" width="300"/>

### CKMonth

This shows all the events for a selected month. You can use this for MacOs and iPad

<img src="https://github.com/Haskins-io/SwiftUiCalendarKit/blob/main/Screenshots/CKMonth.png" width="300"/>

### CKCompactDay

This shows all the events for a selected date. Best used on an iPhone

<img src="https://github.com/haskins-io/SwiftUiCalendarKit/blob/main/Screenshots/CKCompactDay.png" width="300"/>

### CKCompactWeek

This shows all the events for a selected week. This only shows a single timeline and you select the date you want from the top. Best used on an iPhone

<img src="https://github.com/Haskins-io/SwiftUiCalendarKit/blob/main/Screenshots/CKCompactWeek.png" width="300"/>

### CKCompactMonth

This shows all the events for a selected month. This shows a picker style calendar. Best used on an iPhone

<img src="https://github.com/haskins-io/SwiftUiCalendarKit/blob/main/Screenshots/CKCompactMonth.png" width="300"/>


## Events
There is a Protocal called CKEventSchema that defines what a Calendar entry should look like. There is an example implementation called 'CKEvent'. Though you can use your own classes/structs if you want and simply add a reference to the protocol.

## Navigation
For the Compact calendars you can pass in a View that provides your EventDetail. This is used as part of a NavigationLink and when tapping an Event it will navigate to the passed View. See in the Examples folder.

For the other calenders there is an CalendarObserver class. When you click/tap on an event it will set the event object that was tapped on the class and then set 'eventSelected' flag to be true. How you handle this is down to your application.

## FAQ
### Why are you using two dates to define an event, when you could be using a DateInterval.?
The simple answer is that I'm using this with SwiftData, and it doesn't support DateInterval as a data type. There might be a way around this, but I'm good with what I have at the moment.

### Why are you storing Colors as String?
Same answer as above. The Protocol does force you to implement functions to return Colors. How you implement them is up to you. The Color extension provides a function that converts a Hex string to a color. You might want to use this, or provide your own soluion.

## Known Issues
### Overlapping events
While the code can handle overlapping events, and display them correctly, there are some overlay scenarios which it doesn't handle very well.


# SwiftUiCalendarKit

I'm developing this as part of an application that requires multiple calendar views, on different devices. This means at this time I'm trying to get the functionality that I need for my larger application, and not spending too much time at this moment looking at localisation, customisations, etc. I'm sure I'll get around to those at some time, just not planned as yet.

All the calendars are written purely in SwiftUI.

What is on the master branch should work.

## Available Calendars
### CKTimelineDay

This shows all the events for a selected date. You can use this for MacOs and iPad

<img src="https://github.com/Haskins-io/SwiftUiCalendarKit/blob/master/Screenshots/day.png" width="300"/>
<img src="https://github.com/Haskins-io/SwiftUiCalendarKit/blob/master/Screenshots/day_iphone.png" width="300"/>

### CKTimelineWeek

This shows all the events for a selected week. You can use this for MacOs and iPad

<img src="https://github.com/Haskins-io/SwiftUiCalendarKit/blob/master/Screenshots/week.gif" width="300"/>

### CKMonth

This shows all the events for a selected month. You can use this for MacOs and iPad

<img src="https://github.com/Haskins-io/SwiftUiCalendarKit/blob/master/Screenshots/month.gif" width="300"/>

### CKCompactWeek

This shows all the events for a selected week. This only shows a single timeline and you select the date you want from the top. Best used on an iPhone

<img src="https://github.com/Haskins-io/SwiftUiCalendarKit/blob/master/Screenshots/compact_week.gif" width="300"/>

### CKCompactMonth

This shows all the events for a selected month. This shows a picker style calendar. Best used on an iPhone

<img src="https://github.com/Haskins-io/SwiftUiCalendarKit/blob/master/Screenshots/compact_month.gif" width="300"/>


## Events
There is a Protocal called CKEventSchema that defines what a Calendar entry should look like. There is an example implementation called 'CKEvent'. Though you can use your own classes/structs if you want and simply add a reference to the protocol.

## FAQ
### Why are you using two dates to define an event, when you could be using a DateInterval.?
The simple answer is that I'm using this with SwiftData, and it doesn't support DateInterval as a data type. There might be a way around this, but I'm good with what I have at the moment.


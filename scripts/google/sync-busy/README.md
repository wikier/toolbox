# Sync busy form the personal calendar to work

Assuming both calendars are Google, simple Google Script that checks your personal calendar's free/busy and mirrors each busy slot as a "Personal Busy" block on your work calendar.

1. Go to script.google.com and create a new project. Click Services + and add Google Calendar API. Then paste the source code.
2. Run it once to grant permissions.
3. Add a trigger so it keeps running on its own: click the clock icon, then Add trigger, choose syncBusy, time-driven, wherever it works for you.


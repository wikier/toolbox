function syncBusy() {
  const PERSONAL = 'foo@gmail.com'; // your personal calendar
  const start = new Date(); start.setHours(0, 0, 0, 0);
  const end = new Date(start.getTime() + 30 * 864e5); // 1 month ahead
  const work = CalendarApp.getDefaultCalendar();

  // Busy, timed events from the personal calendar, keyed by event ID
  const src = new Map();
  (Calendar.Events.list(PERSONAL, {
    timeMin: start.toISOString(), timeMax: end.toISOString(),
    singleEvents: true, maxResults: 2500
  }).items || [])
    .filter(e => e.status !== 'cancelled' && e.transparency !== 'transparent' && e.start.dateTime)
    .forEach(e => src.set(e.id, {
      title: e.summary || 'Personal Busy', s: new Date(e.start.dateTime), f: new Date(e.end.dateTime)
    }));

  // Update or delete existing copies
  work.getEvents(start, end).filter(e => e.getTag('sync') === 'personal').forEach(e => {
    const id = e.getTag('src'), p = src.get(id);
    if (!p) return e.deleteEvent();
    if (e.getTitle() !== p.title) e.setTitle(p.title);
    if (e.getColor() !== '8') e.setColor(CalendarApp.EventColor.GRAY);
    if (e.getStartTime().getTime() !== p.s.getTime() || e.getEndTime().getTime() !== p.f.getTime())
      e.setTime(p.s, p.f);
    src.delete(id);
  });

  // Create copies for new events
  src.forEach((p, id) => {
    const e = work.createEvent(p.title, p.s, p.f);
    e.setTag('sync', 'personal'); e.setTag('src', id);
    e.setVisibility(CalendarApp.Visibility.PRIVATE);
    e.setColor(CalendarApp.EventColor.GRAY);
  });
}

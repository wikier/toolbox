function syncBusy() {
  const PERSONAL = 'foo@gmail.com'; // your personal calendar
  const start = new Date(); start.setHours(0, 0, 0, 0);
  const end = new Date(start.getTime() + 30 * 864e5); // 1 month ahead
  const work = CalendarApp.getDefaultCalendar();

  const busy = new Set(Calendar.Freebusy.query({
    timeMin: start.toISOString(), timeMax: end.toISOString(), items: [{ id: PERSONAL }]
  }).calendars[PERSONAL].busy.map(b => new Date(b.start).getTime() + '|' + new Date(b.end).getTime()));

  work.getEvents(start, end).filter(e => e.getTag('sync') === 'personal').forEach(e => {
    const k = e.getStartTime().getTime() + '|' + e.getEndTime().getTime();
    if (!busy.delete(k)) e.deleteEvent();      // remove blocks that no longer exist
  });

  busy.forEach(k => {
    const [s, f] = k.split('|').map(Number);
    work.createEvent('Busy (personal)', new Date(s), new Date(f)).setTag('sync', 'personal');
  });
}

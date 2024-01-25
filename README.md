=NH Weather Closings=

This script looks for weather closings reported on the WMUR site and filters them for you by a list you provide (DISTRICTS).

It then creates a basic HTML file with only your closings included.

It then launches chromium with those closings shown.  This is meant to be used on a home automation system.

For our disticts we need to check every half hour from 5am to 7am because they cancel and change very late.

After 7am it will keep checking only if it found something before 7am that day, to save load on the server.  This case is needed for when they change a delayed opening into a snow day.

See the crontab example for running this on a schedule.

All this so we're not sitting wondering where the bus is, more than a mile down an icy road!

Remember to thank WMUR for maintaining their service.

Should the need arise the configuration could be moved to a separate file.

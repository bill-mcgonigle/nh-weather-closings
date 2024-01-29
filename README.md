# NH Weather Closings

This script looks for weather closings reported on the data provider's site and filters them for you by a list you provide (DISTRICTS).

It then creates a basic HTML file with only your closings included.

It then launches chromium with those closings shown.  This is meant to be used on a home automation system.

For our disticts we need to check every half hour from the start time to the cutoff time because they cancel and change very late.

After the cutoff time it will keep checking only if it found something before the cutoff time that day, to save load on the server.  This case is needed for when they change a delayed opening into a snow day.

See the crontab example for running this on a schedule.

All this so we're not sitting wondering where the bus is, more than a mile down an icy road!

Remember to thank the datasource providers for maintaining their service.

Should the need arise the configuration could be moved to a separate file.

Auto-closing the tab requires a manual setting in Firefox ... TBD on Chrom*.

Current datasources:

  NH - WMUR


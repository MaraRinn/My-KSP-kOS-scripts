print "Booting.".
switch to 0.
runoncepath("checkports").
set launch_delay_full_throttle to false.

if core:tag:length > 0 {
	set ship:name to core:tag.
	if exists(core:tag) runoncepath(core:tag).
	}

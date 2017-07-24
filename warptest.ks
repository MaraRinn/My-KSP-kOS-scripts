set requested_warp to 1.
until requested_warp = 6 {
	set warp to requested_warp.
	wait until kuniverse:timewarp:issettled.
	set before to time:seconds.
	set warp to 0.
	wait until kuniverse:timewarp:issettled.
	set after to time:seconds.
	set duration to after - before.
	print "Dropping out of warp " + requested_warp + " took " + duration + "s.".
	set requested_warp to requested_warp + 1.
	}

// Execute the next manoeuvre node.
//  - estimate burn time based on maximum acceleration
//  - align ship to manoeuvre vector
//  - warp to manoeuvre node
//    - drop out of warp at 10 minutes to realign to manoeuvre vector
//  - perform burn
//  - delete the manoeuvre node

clearscreen.

set nd to nextnode.
set NAVMODE to "Orbit".
lock burnvector to nd:deltav.
lock acceleration to ship:maxthrust / ship:mass.
lock burnDuration to burnvector:mag / acceleration.
lock guardTime to time:seconds + nd:eta - (burnDuration/2 + 5). 
lock dPitch to round(abs(burnvector:direction:pitch - ship:facing:pitch),2).
lock dYaw to round(abs(burnvector:direction:yaw - ship:facing:yaw),2).

// Realignment
function AlignToBurn {
	print "Aligning to burn vector.              " at (0,3).
	until dPitch < 0.15 and dYaw < 0.15 {
		print "   dPitch: " + dPitch + "        " at (0,4).
		print "     dYaw: " + dYaw + "        " at (0,5).
		}
	print "                                   " at (0,3).
	print "                                   " at (0,4).
	print "                                   " at (0,5).	
	}

// Warping
function WarpToTime {
	parameter destinationTime.
	until time:seconds > destinationTime {
		set interval to destinationTime - time:seconds.
		print "Waiting " + round(interval) + "s.              " at (0,4).
		if interval > 150000 {
			set warp to 7.
			}
		else if interval > 15000 {
			set warp to 6.
			}
		else if interval > 1500 {
			set warp to 5.
			}
		else if interval > 150 {
			set warp to 4.
			}
		else if interval > 75 {
			set warp to 3.
			}
		else if interval > 15 {
			set warp to 2.
			}
		else if interval > 8 {
			set warp to 1.
			}
		else {
			set warp to 0.
			}
		wait 1.
		}
	}


run deltavstage.
set dV to deltaVstage().
if dV < burnvector:mag {
	stage.
	wait 1.
	until maxthrust > 0 {
		stage.
		wait 1.
		}
	}

set useSas to false.
if useSas {
	unlock steering.
	sas on.
	wait 0.5. // SAS turns on "stability" mode by default.
	set sasmode to "MANEUVER".
	}
else {
	sas off.
	lock steering to burnvector:direction.
	}
AlignToBurn().

// Warp to 10 minute mark to realign.
if guardTime - time:seconds > 800 {
	print "Warping to realignment point.    " at (0,3).
	set alignTime to time:seconds + nd:eta - 600.
	WarpToTime(alignTime).
	AlignToBurn().
	}

// Warp to the manoeuvre node
print "Warping to node.               " at (0,3).
WarpToTime(guardTime).
set warp to 0.
wait until kuniverse:timewarp:issettled.

print "Performing manoeuvre.             " at (0,3).
print "                                  " at (0,4).
wait until time:seconds > guardTime.

set dV0 to burnvector.
set done to false.
set desiredThrottle to 0.
lock throttle to desiredThrottle.
until done {
	if MAXTHRUST = 0 {
		STAGE.
		}
	else if dPitch > 0.15 or dYaw > 0.15 {
		set desiredThrottle to 0.
		AlignToBurn().
		}
	else {
		set throttleSetting to min(burnvector:mag/acceleration/5, 1).
		if burnvector:mag < 0.11 {
			set done to true.
			set throttleSetting to 0.
			}
		set desiredThrottle to throttleSetting.
		}
	wait 0.1.
	}

unlock all.
wait 1.
remove nextnode.

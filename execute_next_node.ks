// Execute the next manoeuvre node.
//  - estimate burn time based on maximum acceleration
//  - align ship to manoeuvre vector
//  - warp to manoeuvre node
//    - drop out of warp at 10 minutes to realign to manoeuvre vector
//  - perform burn
//  - delete the manoeuvre node

runoncepath("lib/vessel_operations.ks").
set myNode to nextnode.
lock SunwardVector to -sun:position.
set NAVMODE to "Orbit".
if sas and (sasmode = "PROGRADE") {
	lock burnvector to prograde:vector.
	}
else if sas and (sasmode = "RETROGRADE") {
	lock burnvector to retrograde:vector.
	}
else {
	lock burnvector to myNode:deltav.
	}
lock acceleration to ship:maxthrust / ship:mass.
lock burnDuration to burnvector:mag / acceleration.
lock guardTime to time:seconds + myNode:eta - (burnDuration/2 + 1). 
lock burnIsAligned to (vang(burnvector, ship:facing:vector) < 0.50) or (burnvector:mag < 0.001).

if sas {
	unlock steering.
	wait 0.5. // SAS turns on "stability" mode by default.
	if NextNode:deltav:mag > 0.01 and not (sasmode = "PROGRADE" or sasmode = "RETROGRADE") { set sasmode to "MANEUVER". }.
	}
else {
	lock steering to LookDirUp(burnvector, SunwardVector).
	}
wait until burnIsAligned.

// Warp to 10 minute mark to realign.
if guardTime - time:seconds > 600 {
	print "Warping to realignment point.".
	set alignTime to time:seconds + myNode:eta - 600.
	WarpToTime(alignTime).
	wait until burnIsAligned.
	}

// Warp to the manoeuvre node
print "Warping to node.".
WarpToTime(guardTime).

print "Performing manoeuvre.".
wait until time:seconds > guardTime.

set done to false.
set desiredThrottle to 0.
lock throttle to desiredThrottle.
until done {
	if not burnIsAligned {
		print "aligning".
		set desiredThrottle to 0.
		wait until burnIsAligned.
		}
	else {
		set throttleIntent to burnvector:mag/acceleration.
		set throttleSetting to min(throttleIntent, 1).
		if burnvector:mag < 0.1 or sas and (sasMode="PROGRADE" or sasMode="RETROGRADE") {
			set done to true.
			set throttleSetting to 0.
			}
		set desiredThrottle to throttleSetting.
		}
	wait 0.1.
	}

print "Manoeuvre completed.".
set desiredThrottle to 0.
SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.
unlock all.
remove nextnode.
wait 1.

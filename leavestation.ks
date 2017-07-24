// Undock from the current station and move to a safe orbit.
//  - push back
//  - align prograde
//  - light burn to raise orbit by 10km
//  - create manoeuvre node for circularisation

run orbital_mechanics.

clearscreen.
print "LEAVING STATION         " at (0,0).
print "===============         " at (0,1).
print "                        " at (0,2).

print "Pushing back from station.       " at (0,3).
sas on.
rcs on.
set ship:control:fore to -1.
wait 5.
set ship:control:neutralize to true.
set NAVMODE to "ORBIT".
set SASMODE to "PROGRADE".
set OldApoapsis to SHIP:Apoapsis.

print "Aligning to prograde.              " at (0,3).
set NAVMODE to "Orbit".
lock dPitch to round(abs(prograde:pitch - ship:facing:pitch),2).
lock dYaw to round(abs(prograde:yaw - ship:facing:yaw),2).
until dPitch < 0.15 and dYaw < 0.15 {
	print "   dPitch: " + dPitch + "      " at (0,4).
	print "     dYaw: " + dYaw + "      " at (0,5).
	}
print "                                   " at (0,4).
print "                                   " at (0,5).

print "Raising orbit to clear station         " at (0,3).
print "   Old Apoapsis: " + round(OldApoapsis,2) at (0,4).
set desiredThrottle to 0.1.
lock THROTTLE to desiredThrottle.
until SHIP:Apoapsis - OldApoapsis > 9999 {
	print "   New Apoapsis: " + round(SHIP:Apoapsis,2) + "      " at (0,5).
	}
unlock THROTTLE.
until abs(OldApoapsis - SHIP:Apoapsis) < 1 {
	print "   New Apoapsis: " + round(SHIP:Apoapsis,2) + "   " at (0,5).
	set OldApoapsis to SHIP:Apoapsis.
	wait 1.
	}
print "                                 " at (0,3).
print "                                 " at (0,4).

print "Preparing circularisation node       " at (0,3).
create_circularise_node(true).

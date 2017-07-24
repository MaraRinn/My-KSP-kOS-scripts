//hellolaunch
// Launch a rocket into the desired orbit, and circularise at apoapsis.

DECLARE PARAMETER orbit_altitude.
run create_circularise_node.

CLEARSCREEN.
print "LAUNCHING" at (0,0).
print "=========" at (0,1).

SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0. // Stop throttle resetting to 50%
set throttle_position to 0.
lock throttle to throttle_position.
lock localG to (body:mu / (body:radius + ship:altitude)^2).
set maxThrottle to (5 * localG * mass)/maxthrust.
set desiredHeading to HEADING(90,0).

WHEN SHIP:VELOCITY:SURFACE:MAG < 1 THEN {
	set STEERING TO UP.
	set throttle_position TO maxThrottle.
	RCS ON.
	SAS OFF.
	gear off.
	PRINT "Clearing launch area" AT (0,3).
	STAGE.
	wait 0.1.
	}

WHEN ALT:RADAR > 100 and apoapsis < orbit_altitude THEN {
  UNLOCK STEERING.
  LOCK STEERING TO desiredHeading.
  PRINT "Burning to orbit      " AT(0,3).
  }

set ten_percent to orbit_altitude * 0.9.
set one_percent to orbit_altitude * 0.99.

until ship:apoapsis > orbit_altitude {
	print "Correcting orientation    " AT(0,3).
  wait until abs (ship:facing:pitch - desiredHeading:pitch) < 0.15 and abs(ship:facing:yaw - desiredHeading:yaw) < 0.15.
  if ship:apoapsis > orbit_altitude {
    set throttle_position to 0.
    }
  else if ship:apoapsis > one_percent {
		print "Just a little further...  " at (0,3).
    set throttle_position to 0.1.
    }
  else if ship:apoapsis > ten_percent {
    print "Easy does it!           " at (0,3).
    set throttle_position to 0.3.
    }
  else {
   print "Full speed ahead!        " at (0,3).
  	set throttle_position to 1.
  	}
  wait 0.1.
  }
set throttle_position to 0.

create_circularise_node(true).
set circularisation to nextnode.
set deltavArrow to vecDraw(V(0,0,0), circularisation:deltav, RGB(0,0,1), "Circ burn", 1, true, 0.2).
set deltavArrow:vecupdater to { return circularisation:deltav. }.

lock acceleration to maxthrust / mass.
lock burnDuration to circularisation:deltav:mag / acceleration.
lock guardTime to nodeTime - (burnDuration/2 + 5). 

lock burnvector to circularisation:deltav.
set useSas to true.
if useSas {
	unlock steering.
	sas on.
	wait 0.5. // SAS turns on "stability" mode by default.
	set sasmode to "MANEUVER".
	}
else {
	set desiredHeading to burnvector:direction.
	}
print "Aligning to burn vector.              " at (0,4).
wait until abs (burnvector:direction:pitch - ship:facing:pitch) < 0.15 and abs(burnvector:direction:yaw - ship:facing:yaw) < 0.15.
print "                                    " at (0,4).

// Warp to circularisation
print "Warping to circularisation burn.  " at (0,3).
until time:seconds > guardTime {
	set interval to guardTime - time:seconds.
	print "Waiting " + interval + "s.              " at (0,4).
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
	}
set warp to 0.
wait until kuniverse:timewarp:issettled.

print "Circularising orbit.              " at (0,3).
print "                                  " at (0,4).
wait until time:seconds > (nodetime - burnDuration/2).
set throttle_position to 1.
wait until ship:periapsis > ten_percent.
set throttle_position to 0.1.
wait until ship:periapsis > one_percent.
set throttle_position to 0.

remove circularisation.
set deltavArrow:show to false.
unlock all.

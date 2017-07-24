clearscreen.
SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0. // Stop throttle resetting to 50%
set throttle_position to 0.
set desired_heading to 90.
set desired_pitch to 88.
set desired_apoapsis to 80000.
lock throttle to throttle_position.
lock steering to heading(desired_heading, desired_pitch).
lock localG to (body:mu / (body:radius + ship:altitude)^2).

when ship:velocity:surface:mag < 1 then {
	lock steering to up.
	stage.
	set throttle_position to 100.
	}

when ship:velocity:surface:mag > 20 then {
	lock steering to heading(90,88).
	}

WHEN SHIP:VELOCITY:SURFACE:MAG > 200 THEN {
	lock steering to heading(90, (40000-ship:altitude)/40000 * 90).
	}

when ship:altitude > 40000 then {
	print "point to horizon      " at (0,2).
	lock steering to heading(90,0).
	}

WHEN MAXTHRUST = 0 THEN {
    PRINT "Staging".
    STAGE.
    PRESERVE.
}

set transferTank to ship:partsdubbed("Transfer Tank").
set boosterTank to ship:partsdubbed("Booster Tank").

set oxidizerTransfer to TRANSFERALL("OXIDIZER", transferTank, boosterTank).
set oxidizerTransfer:ACTIVE to true.

set fuelTransfer to TRANSFERALL("LIQUIDFUEL", transferTank, boosterTank).
set fuelTransfer:ACTIVE to true.

until ship:apoapsis > desired_apoapsis {
	set throttle_position to min(3 * (localG * mass)/maxthrust, 1.0).
	print "Setting throttle to " + round(throttle_position,2) + "    " at (0,0).
	print "Facing: " + ship:facing + "     " at (0,4).
	print "Surface prograde: " + ship:srfprograde + "     " at (0,5).
	}

until ship:altitude > 70000 {
	print "Waiting.    " at (0,1).
	}

ag1 on.
set throttle_position to 0.
unlock all.
clearscreen.
run circularise(true).
set sasmode to "MANEUVER".

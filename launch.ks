//hellolaunch
// Launch a rocket into the desired orbit, and circularise at apoapsis.

DECLARE PARAMETER orbit_altitude IS 120000.

SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0. // Stop throttle resetting to 50%
set atmosphere_altitude to BODY:ATM:HEIGHT.
set turn_altitude to atmosphere_altitude * 2 / 3. // FIXME: need to fix gravity turns
set max_acceleration_cap to 30.
set acceleration_cap to max_acceleration_cap. // m/s^2
set runmode to "where are we?".
set fuelTransferCheck to false.
lock localG to (body:mu / (body:radius + ship:altitude)^2).

set throttle_position to 0.
lock throttle to throttle_position.
sas off.
rcs on.

declare function terrain_height {
	if body = minmus {
		return 5800.
		}
	else if body = ike {
		return 12800.
		}
	else if body = mun {
		return 7100.
		}
	return 0.
	}

CLEARSCREEN.
print "LAUNCHING" at (0,0).
print "=========" at (0,1).

until runmode = "finished" {
	if runmode = "where are we?" {
		if ship:velocity:surface:mag < 1 {
			set runmode to "leaving launch site".
			}
		else if ship:velocity:surface:mag > (30 * localG) {
			set runmode to "gravity turn".
			}
		else {
			set runmode to "clearing launch area".
			}
		}

	else if runmode = "leaving launch site" {
		lock steering to heading(90,88).
		if maxthrust = 0 { // Don't stage if engines are already active
			until maxthrust > 0 {
				print "ATTEMPTING TO START ENGINES       " at (0,3).
				stage.
				wait 1.
				}
			}
		set max_accel to maxthrust / mass.
		set acceleration_cap to localG * 3.
		if gear gear off.
		// FIXME: stage ground support equipment too
		if ship:velocity:surface:mag > (10 * localG) set runmode to "clearing launch area".
		}

	else if runmode = "clearing launch area" and turn_altitude >= 1 {
		lock steering to heading(90, 80).
		set acceleration_cap to max_acceleration_cap.
		if ship:velocity:surface:mag > (30 * localG) {
			unlock steering.
			set runmode to "gravity turn".
			}
		}
	else if runmode = "clearing launch area" and turn_altitude < 1 {
		if apoapsis > terrain_height() set runmode to "build orbital velocity".
		}
	else if runmode = "gravity turn" and ship:altitude < turn_altitude {
		if sas {
			set sasmode to "PROGRADE".
			}
		else {
			unlock steering.
			sas on.
			}
		}
	else if runmode = "gravity turn" and ship:altitude >= turn_altitude {
		set runmode to "build orbital velocity".
		sas off.
		}

	else if runmode = "build orbital velocity" {
		lock steering to heading(90,0).
		if defined launch_delay_full_throttle and launch_delay_full_throttle {
			set angle_from_up to vectorangle(up:vector, facing:vector).
			if angle_from_up < 80 or angle_from_up > 90 {
				set acceleration_cap to localG * 5.
				}
			else {
				set acceleration_cap to max_acceleration_cap.
				}
			}
		else {
			set acceleration_cap to max_acceleration_cap.
			}
		}

	if ship:altitude > 1000 and MAXTHRUST = 0 {
			print "STAGING TO START ENGINE IN FLIGHT?            " at (0,3).
			STAGE.
			wait 2.
	}

	if not fuelTransferCheck and ship:velocity:surface:mag > 5 {
		print "checking fuel transfer        " at (0,5).
		set transferTank to ship:partsdubbed("Transfer Tank").
		set storageTank to ship:partsdubbed("Fuel Storage").
		for tank in storageTank {
			transferTank:add(tank).
			}
		set boosterTank to ship:partsdubbed("Booster Tank").

		if (transferTank.length > 0 and boosterTank.length > 0) {
			set oxidizerTransfer to TRANSFERALL("OXIDIZER", transferTank, boosterTank).
			set oxidizerTransfer:ACTIVE to true.

			set fuelTransfer to TRANSFERALL("LIQUIDFUEL", transferTank, boosterTank).
			set fuelTransfer:ACTIVE to true.
			print "fuel transfer started    " at (0,5).
			}
		else {
			print "no fuel transfer required   " at (0,5).
			}
		set fuelTransferCheck to true.
		wait 1.
		}

	// Apply thrust proportionally to current orbital speed and apoapsis error
	// Ideally, figure out how fast we'd have to be going here to make it to the desired altitude
	set max_accel to 0.
	set throttle_cap to 0.
	set throttle_intent to 0.
	set apoapsis_error to max(0, orbit_altitude - apoapsis) / orbit_altitude.
	set speed_portion to ship:velocity:orbit:mag * apoapsis_error.
	if maxthrust > 0 {
		set max_accel to maxthrust / mass.
		set throttle_cap to (acceleration_cap * mass) / maxthrust.
		set throttle_intent to speed_portion / max_accel.
		set throttle_position to min(throttle_cap, throttle_intent).
		}
		
	print runmode + "            " at (0,3).
	print "Throttle Intent: " + round(throttle_intent,2) + "        " at (0,5).
	print "Throttle Cap:    " + round(throttle_cap,2) + "     " at (0,6).
	print round(speed_portion,2) + "     " at (0,7).
	print round(apoapsis_error,2) + "     " at (0,8).
	print round(vectorangle(up:vector, facing:vector),2) + "      " at (0,9).

	if altitude > atmosphere_altitude and (orbit_altitude - apoapsis) < 10 {
		set throttle_position to 0.
		set runmode to "finished".
		}

	wait 0.1.
	}

// If we are launching fuel tanks, ditch the booster unit and its tiny fuel tank.
// Fuel tanks on later stage should be tagged "Transfer Tank" or "Fuel Storage"
set boosterTank to ship:partsdubbed("Booster Tank").
if boosterTank:length > 0 and transferTank:length > 0 {
	print "Reclaiming booster fuel".
	set fuelTransfer:ACTIVE to false.
	set oxidizerTransfer:ACTIVE to false.
	set fuelTransfer to TRANSFERALL("LIQUIDFUEL", boosterTank, transferTank).
	set oxidizerTransfer to TRANSFERALL("OXIDIZER", boosterTank, transferTank).
	set fuelTransfer:ACTIVE to true.
	set oxidizerTransfer:ACTIVE to true.
	wait until not fuelTransfer:ACTIVE.
	wait until not oxidizerTransfer:ACTIVE.
	set throttle_position to 0.1.
	wait 0.1.
	set throttle_position to 0.
	}

rcs off.
unlock all.
until maxthrust > 0 {
	print "Ditching empty stage.".
	stage.
	wait 1.
	}
wait 1.

run "circularise".
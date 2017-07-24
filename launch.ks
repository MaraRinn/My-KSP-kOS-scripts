//hellolaunch
// Launch a rocket into the desired orbit, and circularise at apoapsis.

DECLARE PARAMETER orbit_altitude.

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

CLEARSCREEN.
print "LAUNCHING" at (0,0).
print "=========" at (0,1).

until runmode = "finished" {
	if runmode = "where are we?" {
		if ship:velocity:surface:mag < 1 {
			set runmode to "leaving launch site".
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
		set acceleration_cap to localG * 2.
		if gear gear off.
		if ship:velocity:surface:mag > (10 * localG) set runmode to "clearing launch area".
		}

	else if runmode = "clearing launch area" and turn_altitude > 0 {
		// This results in large angle of attack at higher altitudes where the rocket is climbing faster.
		// It would be nice if the entire flight could be managed based on angle of attack
		lock steering to heading(90, (turn_altitude-ship:altitude)/turn_altitude * 90).
		set acceleration_cap to max_acceleration_cap.
		set runmode to "gravity turn".
		}
	else if runmode = "clearing launch area" and turn_altitude < 1 {
		set runmode to "build orbital velocity".
		}

	else if runmode = "gravity turn" and ship:altitude >= turn_altitude {
		set runmode to "build orbital velocity".
		}

	else if runmode = "build orbital velocity" {
		lock steering to heading(90,0).
		if launch_delay_full_throttle {
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

	if not fuelTransferCheck and runmode = "gravity turn" {
		print "checking fuel transfer    " at (0,5).
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

	if altitude > atmosphere_altitude and (orbit_altitude - apoapsis) < 10 {
		set throttle_position to 0.
		set runmode to "coasting to circularisation".
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
	print round(throttle_intent,2) + "        " at (0,5).
	print round(throttle_cap,2) + "     " at (0,6).
	print round(speed_portion,2) + "     " at (0,7).
	print round(apoapsis_error,2) + "     " at (0,8).
	print round(vectorangle(up:vector, facing:vector),2) + "      " at (0,9).

	wait 0.1.

	if runmode = "coasting to circularisation" and maxthrust > 0 {
		set throttle_position to 0.
		set runmode to "finished".
		}
	}

unlock all.
until maxthrust > 0 {
	stage.
	wait 1.
	}

run orbital_mechanics.
create_circularise_node(true).
run execute_next_node.

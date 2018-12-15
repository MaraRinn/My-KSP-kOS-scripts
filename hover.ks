parameter desired_altitude is 100.

SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0. // Stop throttle resetting to 50%
set my_throttle to 0.
lock throttle to my_throttle.
rcs on.
set FLEVEL to STAGE:LIQUIDFUEL.
set runmode to 1.
set cancelHorizontal to false.
sas off.
set steeringVec to up:vector.
lock steering to LookDirUp(steeringVec, ship:North:Vector).

set RUNMODE_HOVER to 1.
set RUNMODE_DESCEND to 2.
set RUNMODE_END to 0.

if defined zeroAltitude {
	set heightAdjustment to zeroAltitude.
	}
else {
	set heightAdjustment to 0.
	}
lock groundDistance to ship:altitude - ship:geoposition:terrainHeight - heightAdjustment.
lock g to ship:body:mu / (ship:body:radius + ship:altitude)^2.
lock maxAcceleration to ship:maxThrust / ship:mass.
lock maxVerticalSpeed to max(0,sqrt(abs(desired_altitude - groundDistance) * 2 * g)).
lock minVerticalSpeed to min(0,0 - sqrt(abs(desired_altitude - groundDistance) * 2 * (maxAcceleration * 0.5 - g))).
lock horizontalVelocity to VectorExclude(up:vector, ship:velocity:surface).

// Control altitude by adjusting speed
// Black Magic
set Ku to 2.
set Tu to 0.25.
set Kp to 0.6 * Ku.
set Ki to 2 * Kp / Tu.
set Kd to Kp * Tu / 8.
set altitude_pid to PIDLoop(3, 0, 0, maxVerticalSpeed, minVerticalSpeed).
set altitude_pid:setpoint to desired_altitude.
set desired_velocity_vertical to altitude_pid:update(time:seconds, groundDistance + ship:verticalSpeed).

// Control speed by adjusting acceleration
// Black Magic
set Ku to 2.
set Tu to 0.25.
set Kp to 0.6 * Ku.
set Ki to 2 * Kp / Tu.
set Kd to Kp * Tu / 8.
set velocity_pid to PIDLoop(3, 0, 0).
set velocity_pid:setpoint to desired_velocity_vertical.
set desiredHorizontalAcceleration to V(0,0,0).
set desiredVerticalAcceleration to velocity_pid:update(time:seconds, ship:verticalSpeed) * up:vector.
if cancelHorizontal {
	set desiredAcceleration to desiredVerticalAcceleration + desiredHorizontalAcceleration.
	}
else {
	set desiredAcceleration to desiredVerticalAcceleration.
	}

set steeringVec to desiredAcceleration.
set my_throttle to desiredAcceleration:mag / maxAcceleration.

gear off.

on GEAR {
	preserve.
	if gear {
		print "Gear lowered".
		set runmode to 2.
		brakes off.
	}
	else {
		print "Gear raised".
		set runmode to 1.
		brakes off.
		}
	}

on BRAKES {
	preserve.
	if runmode = RUNMODE_HOVER {
		set cancelHorizontal to brakes.
		}
	else if runmode = RUNMODE_DESCEND {
		set cancelHorizontal to brakes.
		set desired_altitude to ship:altitude.
		set altitude_pid:setpoint to desired_altitude.
		set runmode to RUNMODE_HOVER.
		gear off.
		brakes off.
		}
	else {
		set runmode to RUNMODE_END.
		}
	}

function RefreshDisplay {
	parameter mode is "HOVER CONTROL".
	clearscreen.
	print "== " + mode + " ==".
	print "Altitude:   " + round(altitude,1).
	print "Ground:     " + round(groundDistance,1) + " (" + round(desired_altitude,1) + ")    ".
	print "Vertical:   " + round(ship:verticalSpeed,1) + " (" + round(desired_velocity_vertical,1) + ")    ".
	print "Horizontal: " + round(horizontalVelocity:mag,1).
	print "HZ Acc:     " + round(desiredHorizontalAcceleration:mag, 1).
	print "HZ avail:   " + round(availableHorizontalAcceleration:mag, 1).
	print "Cancel: " + cancelHorizontal.
	}

until runmode = RUNMODE_END {
	IF RUNMODE = RUNMODE_HOVER {
		set altitude_pid:maxoutput to maxVerticalSpeed.
		set altitude_pid:minoutput to minVerticalSpeed.
		set desired_velocity_vertical to altitude_pid:Update( time:seconds, groundDistance ).
		set velocity_pid:setPoint to desired_velocity_vertical.
		set desiredHorizontalAcceleration to (horizontalVelocity / -3).
		set desiredVerticalAcceleration to max(velocity_pid:update( time:seconds, ship:verticalSpeed ),0) * up:vector.

		set verticalAngle to VectorAngle(ship:facing:vector, up:vector).
		set availableHorizontalAcceleration to desiredVerticalAcceleration * tan(verticalAngle).

		if cancelHorizontal {
			set desiredAcceleration to desiredVerticalAcceleration + desiredHorizontalAcceleration.
			set availableAcceleration to desiredVerticalAcceleration + availableHorizontalAcceleration.
			}
		else {
			set desiredAcceleration to desiredVerticalAcceleration.
			set availableAcceleration to desiredVerticalAcceleration.
			}

		if desiredAcceleration:mag > 0.1 {
			set desiredHeading to desiredAcceleration:normalized.
			}
		else {
			set desiredHeading to up:vector.
			}
		set steeringVec to desiredHeading.
		set my_throttle to availableAcceleration:mag / maxAcceleration.
		RefreshDisplay("HOVERING").

		if stage:liquidfuel < 0.5*FLEVEL {
			set runmode to RUNMODE_DESCEND.
			gear on.
			}	
		}
	
	IF RUNMODE = RUNMODE_DESCEND {
		set altitude_pid:maxoutput to maxVerticalSpeed.
		set altitude_pid:minoutput to minVerticalSpeed.
		set desired_velocity_vertical to (0 - max(groundDistance/10,1)).
		RefreshDisplay("LANDING").
		set velocity_pid:setpoint to desired_velocity_vertical.
		set my_throttle to velocity_pid:Update( time:seconds, ship:verticalSpeed).
		if ship:status = "LANDED" {
			set RUNMODE to RUNMODE_END.
			brakes off.
			}
		}
	wait 0.1.
	}

set my_throttle to 0.
set Ship:Control:PilotMainThrottle to 0.
rcs off.
sas off.

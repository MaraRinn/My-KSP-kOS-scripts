parameter desired_altitude is 100.

SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0. // Stop throttle resetting to 50%
set my_throttle to 0.
lock throttle to my_throttle.
rcs on.
set FLEVEL to STAGE:LIQUIDFUEL.
set runmode to 1.
set cancelHorizontal to false.
sas off.
set steeringVec to up.
lock steering to steeringVec.

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
lock minVerticalSpeed to min(0,0 - sqrt(abs(desired_altitude - groundDistance) * 2 * (maxAcceleration - g))).

set altitude_pid to PIDLoop(1, 0, 0, maxVerticalSpeed, minVerticalSpeed).
set altitude_pid:setpoint to desired_altitude.
set desired_velocity_vertical to altitude_pid:update(time:seconds, groundDistance + ship:verticalSpeed).

// Black Magic
set Ku to 1.2.
set Kp to 0.6 * Ku.
set velocity_pid to PIDLoop(Kp, 0, 0, 0, 1).
set velocity_pid:setpoint to desired_velocity_vertical.
set my_throttle to velocity_pid:update(time:seconds, ship:verticalSpeed).

on GEAR {
	preserve.
	if gear {
		print "Gear lowered".
		set runmode to 2.
	}
	else {
		print "Gear raised".
		set runmode to 1.
		}
	}

on BRAKES {
	preserve.
	if runmode = 1 {
		set cancelHorizontal to brakes.
		}
	else {
		set runmode to 0.
		}
	}

function RefreshDisplay {
	parameter mode is "HOVER CONTROL".
	clearscreen.
	print "== " + mode + " ==".
	print "Altitude: " + altitude.
	print "Ground: " + groundDistance + " (" + desired_altitude + ")    ".
	print "Vertical: " + ship:verticalSpeed + " (" + desired_velocity_vertical + ")    ".
	}

set throttleSettings to List().

until runmode = 0 {	
	IF RUNMODE = 1 {
		set altitude_pid:maxoutput to maxVerticalSpeed.
		set altitude_pid:minoutput to minVerticalSpeed.
		RefreshDisplay("HOVERING").
		set desired_velocity_vertical to altitude_pid:Update( time:seconds, groundDistance).
		set velocity_pid:setPoint to desired_velocity_vertical.
		set my_throttle to velocity_pid:UPDATE( time:seconds, ship:verticalSpeed ).
		wait 0.1.
		}
	
	IF RUNMODE = 2 {
		set altitude_pid:maxoutput to maxVerticalSpeed.
		set altitude_pid:minoutput to minVerticalSpeed.
		set desired_velocity_vertical to (0 - max(groundDistance/10,1)).
		RefreshDisplay("LANDING").
		set velocity_pid:setpoint to desired_velocity_vertical.
		set my_throttle to velocity_pid:Update( time:seconds, ship:verticalSpeed).
		wait 0.1.
		}
		
	if stage:liquidfuel < 0.5*FLEVEL{
		set runmode to 2.
		}	
	}

set my_throttle to 0.
set Ship:Control:PilotMainThrottle to 0.
rcs off.
sas off.

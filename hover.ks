parameter desiredAltitude is 100.

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

set East to VCRS(Up:Vector, North:Vector).
set NorthArrow to VecDraw(V(0,0,0), North:Vector * 20, blue, "N", 1, true, 1).
set UpArrow to VecDraw(V(0,0,0), Up:Vector * 20, blue, "U", 1, true, 1).
set EastArrow to VecDraw(V(0,0,0), East * 20, blue, "E", 1, true, 1).

if defined zeroAltitude {
	set heightAdjustment to zeroAltitude.
	}
else {
	set heightAdjustment to 0.
	}
lock groundDistance to ship:altitude - ship:geoposition:terrainHeight - heightAdjustment.
lock g to ship:body:mu / (ship:body:radius + ship:altitude)^2.
lock maxAcceleration to ship:maxThrust / ship:mass.
// maximum vertical is the highest upwards speed we want in order to reach the target height
lock maxVerticalSpeed to max(0,sqrt(abs(desiredAltitude - groundDistance) * 2 * g)).
// minimum vertical speed is the highest downwards speed we want in order to be able to stop at the target height (and eg: not hit the ground)
lock minVerticalSpeed to min(0,0 - sqrt(abs(desiredAltitude - groundDistance) * 2 * (maxAcceleration * 0.8 - g))).
lock horizontalVelocity to VectorExclude(up:vector, ship:velocity:surface).

// Control altitude by adjusting speed
// Black Magic
set Ku to 2.
set Tu to 0.25.
set Kp to 0.6 * Ku.
set Ki to 2 * Kp / Tu.
set Kd to Kp * Tu / 8.
set verticalSpeed_pid to PIDLoop(3, 0.3, 1, maxVerticalSpeed, minVerticalSpeed).
set verticalSpeed_pid:setpoint to desiredAltitude.
set desiredVerticalVelocity to verticalSpeed_pid:update(time:seconds, groundDistance + ship:verticalSpeed).

// Control speed by adjusting acceleration
// Black Magic
set Ku to 2.
set Tu to 0.25.
set Kp to 0.6 * Ku.
set Ki to 2 * Kp / Tu.
set Kd to Kp * Tu / 8.
set acceleration_pid to PIDLoop(3, 0, 0).
set acceleration_pid:setpoint to desiredVerticalVelocity.
set desiredVerticalAcceleration to acceleration_pid:update(time:seconds, ship:verticalSpeed) * up:vector.

// Black Magic
set Kp to 0.2.
set Ki to 0.
set Kd to 0.5.

set xAcceleration_pid to PIDLoop(Kp, Ki, Kd, -g, g).
set xAcceleration_pid:setPoint to 0.
set yAcceleration_pid to PIDLoop(Kp, Ki, Kd, -g, g).
set yAcceleration_pid:setPoint to 0.

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
		set desiredAltitude to ship:altitude.
		set verticalSpeed_pid:setpoint to desiredAltitude.
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
	print "Ground:     " + round(groundDistance,1) + " (" + round(desiredAltitude,1) + ")    ".
	print "Vertical:   " + round(ship:verticalSpeed,1) + " (" + round(desiredVerticalVelocity,1) + ")    ".
	print "Horizontal: " + round(horizontalVelocity:mag,1).
	print "xv:         " + round(xVelocity, 1).
	print "yv:         " + round(yVelocity, 1).
	print "HZ Acc:     " + round(desiredHorizontalAcceleration:mag, 1).
	print "HZ avail:   " + round(availableHorizontalAcceleration:mag, 1).
	print "Cancel: " + cancelHorizontal.
	}

until runmode = RUNMODE_END {
	IF RUNMODE = RUNMODE_HOVER {
		set verticalSpeed_pid:maxoutput to maxVerticalSpeed.
		set verticalSpeed_pid:minoutput to minVerticalSpeed.
		set desiredVerticalVelocity to verticalSpeed_pid:Update( time:seconds, groundDistance ).
		set acceleration_pid:setPoint to desiredVerticalVelocity.
		set desiredVerticalAcceleration to max(acceleration_pid:update( time:seconds, ship:verticalSpeed ),0) * up:vector.

		// Control horizontal velocity by adjusting horizontal acceleration
		set xVelocity to vDot(horizontalVelocity, East) / East:mag.
		set desiredxAcceleration to xAcceleration_pid:update(time:seconds, xVelocity) * East.

		set yVelocity to vDot(horizontalVelocity, North:Vector) / North:Vector:mag.
		set desiredyAcceleration to yAcceleration_pid:update(time:seconds, yVelocity) * North:Vector.

		set desiredHorizontalAcceleration to desiredxAcceleration + desiredyAcceleration.

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
		set verticalSpeed_pid:maxoutput to maxVerticalSpeed.
		set verticalSpeed_pid:minoutput to minVerticalSpeed.
		set desiredVerticalVelocity to (0 - max(groundDistance/10,1)).
		RefreshDisplay("LANDING").
		set acceleration_pid:setpoint to desiredVerticalVelocity.
		set my_throttle to acceleration_pid:Update( time:seconds, ship:verticalSpeed).
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
clearvecdraws().

if hastarget {
	set navmode to "SURFACE".
	sas off.
	rcs on.
	wait 0.1.
	lock horizontalVelocity to VectorExclude(up:vector, ship:velocity:surface).
	lock steeringVec to -horizontalVelocity:Normalized.
	lock steering to steeringVec.
	set braking_time to false.
	set throttle_position to 0.
	lock throttle to throttle_position.
	lock target_horizontal_position to vxcl(up:vector, target:position).
	lock distance_on_normal to target_horizontal_position:mag.
	lock zero_speed_direction to -ship:facing:vector:normalized.
	lock zero_speed_distance to (target_horizontal_position * zero_speed_direction) * zero_speed_direction.
	lock maxAcceleration to ship:availablethrust / ship:mass. 
	lock speed to horizontalVelocity:mag.
	lock braking_distance to (speed^2)/(2 * maxAcceleration).

	set Ku to 2.
	set Tu to 1.

	set Kp to 0.7 * Ku.
	set Ki to (0.4 * Kp / Tu).
	set Kd to (0.15 * Kp * Tu).

	until speed < 0.1 {
		clearscreen.
		print "Distance: " + round(zero_speed_distance:mag,1).
		print "Braking:  " + round(braking_distance,1).
		print "Speed:    " + round(speed,1).
		if (braking_distance + speed * 0.2) > zero_speed_distance:mag {
			set throttle_position to 1.
			}
		else {
			set throttle_position to 0.
			}
		wait 0.1.
		}
	}

set throttle_position to 0.
SET SHIP:CONTROL:NEUTRALIZE to True.
unlock all.
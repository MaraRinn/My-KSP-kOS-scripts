function TimeString {
	declare parameter secondsToDisplay.
	
	set daysValue to floor(secondsToDisplay / (3600 * 6)).
	set afterDays to secondsToDisplay - (daysValue * 3600 * 6).
	set hoursValue to floor(afterDays / 3600).
	set afterHours to afterDays - (hoursValue * 3600).
	set minutesValue to floor(afterHours / 60).
	set seconds to floor(afterHours - (minutesValue * 60)).
	return daysValue + "d " + hoursValue + "h " + minutesValue + "m " + seconds + "s".
	}

function DisplayValues {
	parameter readings.
	set maxLabelWidth to 0.
	set maxDataWidth to 0.
	set row to 1.
	for item in readings:keys {
		if item:length > maxLabelWidth { set maxLabelWidth to item:length. }
		set valueString to readings[item]:ToString.
		if valueString:length > maxDataWidth {
			set maxDataWidth to valueString:length.
			}
		}
	for item in readings:keys {
		set valueString to readings[item]:ToString.
		print item:PadRight(maxLabelWidth) + "  " + valueString:PadLeft(maxDataWidth) at (0,row).
		set row to row + 1.
		}
	}

function VectorToCompassAngle {
	parameter V.
	parameter subject is ship.
	set upVec to subject:up:vector.
	set northVec to subject:north:vector.
	set eastVec to VectorCrossProduct(upVec, northVec).
	set velEast to VDOT(V, eastVec).
	set velNorth to VDOT(V, northVec).
	set compass to arctan2(velEast, velNorth).
	if compass < 0 { set compass to compass + 360. }
	return compass.
	}

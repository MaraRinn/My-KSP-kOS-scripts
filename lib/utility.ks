function TimeString {
	declare parameter secondsToDisplay.
	set secondsPerMinute to 60.
	set secondsPerHour to secondsPerMinute * 60.
	set secondsPerDay to secondsPerHour * 6.   // Kerbin days
	set secondsPerYear to secondsPerDay * 426. // Kerbin years
	set displayString to "".

	set yearsValue to floor(secondsToDisplay / secondsPerYear).
	if yearsValue > 0 or displayString:length > 0 { set displayString to displayString + yearsValue + "y ". }
	set afterYears to secondsToDisplay - (yearsValue * secondsPerYear).

	set daysValue to floor(afterYears / secondsPerDay).
	if daysValue > 0 or displayString:length > 0 { set displayString to displayString + daysValue + "d ". }
	set afterDays to afterYears - (daysValue * secondsPerDay).

	set hoursValue to floor(afterDays / secondsPerHour).
	if hoursValue > 0 or displayString:length > 0 { set displayString to displayString + hoursValue + "h ". }
	set afterHours to afterDays - (hoursValue * secondsPerHour).

	set minutesValue to floor(afterHours / secondsPerMinute).
	if minutesValue > 0 or displayString:length > 0 { set displayString to displayString + minutesValue + "m ". }
	set afterMinutes to afterHours - (minutesValue * secondsPerMinute).

	set seconds to floor(afterMinutes).
	set displayString to displayString + seconds + "s".
	return displayString.
	}

function DisplayValues {
	parameter readings.
	parameter row is 1.
	set maxLabelWidth to 0.
	set maxDataWidth to 0.
	set rightMargin to 0.
	// Calculate column widths
	for item in readings:keys {
		if item:length > maxLabelWidth {
			set maxLabelWidth to item:length.
			}
		set valueString to readings[item]:ToString.
		if valueString:length > maxDataWidth {
			set maxDataWidth to valueString:length.
			}
		}
	set rightMargin to terminal:width - maxLabelWidth - maxDataWidth - 2.
	// Now display key/value pairs
	for item in readings:keys {
		set valueString to readings[item]:ToString.
		print item:PadRight(maxLabelWidth) + "  " + valueString:PadLeft(maxDataWidth) + " ":PadLeft(rightMargin) at (0,row).
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

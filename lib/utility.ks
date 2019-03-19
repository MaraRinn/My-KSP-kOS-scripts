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
		if readings[item]:length > maxDataWidth {
			set maxDataWidth to readings[item]:length.
			}
		}
	for item in readings:keys {
		print item:PadRight(maxLabelWidth) + "  " + readings[item]:PadLeft(maxDataWidth) at (0,row).
		set row to row + 1.
		}
	}

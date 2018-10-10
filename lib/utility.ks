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


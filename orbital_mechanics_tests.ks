run "orbital_mechanics".
runoncepath("lib/utility.ks").

set eccentricity to Ike:orbit:eccentricity.
set radToDeg to (360 / (2 * constant:pi)).

set readings to Lexicon().
set readings["IkeEccentricity"] to round(eccentricity, 3) + "".
set readings["IkeMeanEpoch"] to round(Ike:orbit:MeanAnomalyAtEpoch, 3) + "".

function UpdateValues {
	set theta to Ike:orbit:trueanomaly.
	set ea to EccentricAnomalyFromTrueAnomaly(theta, eccentricity).
	set ma to MeanAnomalyFromEccentricAnomaly(ea, eccentricity).
	set ikeMeanAnomaly to MeanAnomalyFromOrbit(ike:orbit).
	set readings["IkeAnomaly"] to round(theta, 3) + "".
	set readings["Seconds"] to round(Time:Seconds, 3) + "".
	set readings["EfromT"] to round(ea, 3) + "".
	set readings["MfromE"] to round(ma, 3) + "".
	set readings["MfromO"] to round(ikeMeanAnomaly, 3) + "".
	set readings["PeriodDiff"] to round(orbit:period - Ike:orbit:period, 3) + "".

	set wT to (360 / Ike:orbit:period).          // °/s
	set wS to (body:mu / ship:orbit:semimajoraxis^3)^0.5 * radToDeg. // °/s
	set shipMeanAnomaly to MeanAnomalyFromOrbit(ship:orbit).
	set currentAngle to ikeMeanAnomaly - shipMeanAnomaly.
	if currentAngle < 0 { set currentAngle to currentAngle + 360. }
	set readings["wT"] to round(wT, 3) + "".
	set readings["wS"] to round(wS, 3) + "".
	set readings["PhaseRate"] to round(wT-wS * 3600, 3) + "".
	set readings["Angle"] to round(currentAngle, 3) + "".
	}

until false {
	UpdateValues().
	DisplayValues().
	wait 1.
	}

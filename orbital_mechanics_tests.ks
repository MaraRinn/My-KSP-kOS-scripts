run "orbital_mechanics".

set eccentricity to Ike:orbit:eccentricity.

until false {
	clearscreen.
	set theta to Ike:orbit:trueanomaly.
	print "Ike true anomaly: " + round(theta, 3).
	print "Ike eccentricity: " + round(eccentricity, 3).
	print "Ike mean @ epoch: " + round(Ike:orbit:MeanAnomalyAtEpoch, 3).
	print "   seconds since: " + round(time:seconds, 3).
	set ea to EccentricAnomalyFromTrueAnomaly(theta, eccentricity).
	print "Calculated E from T: " + round(ea, 3).
	set ma to MeanAnomalyFromEccentricAnomaly(ea, eccentricity).
	print "Calculated M from E:  " + round(ma, 3).
	print "Calculated M from O:  " + round(MeanAnomalyFromOrbit(ike:orbit), 3).
	wait 1.
	}

run "orbital_mechanics".
until abort {
set mean to MeanAnomalyFromOrbit(orbit).
set eaft to EccentricAnomalyFromTrueAnomaly(orbit:TrueAnomaly, orbit:eccentricity).
set eafm to EccentricAnomalyFromMeanAnomaly(mean, orbit:eccentricity).
set taft to TrueAnomalyFromEccentricAnomaly(eaft, orbit:eccentricity).
set tafm  to TrueAnomalyFromEccentricAnomaly(eafm, orbit:eccentricity).
set mafe to MeanAnomalyFromEccentricAnomaly(eaft, orbit:eccentricity).
set mafm to MeanAnomalyFromEccentricAnomaly(eafm, orbit:eccentricity).
clearscreen.
print "EAfT:  " + eaft.
print "EAfM:  " + eafm.
print "True:  " + orbit:TrueAnomaly.
print "TAfT:  " + taft.
print "TAfM:  " + tafm.
print "Mean:  " + mean.
print "MAfT:  " + mafe.
print "MAfM:  " + mafm.
print "LAN:   " + orbit:LAN.
print "AoP:   " + orbit:ArgumentOfPeriapsis.
set taan to (360 - orbit:ArgumentOfPeriapsis). // True anomaly of ascending node
if taan >= 180 {
	set tadn to taan - 180.
	}
else {
	set tadn to taan + 180.
	}
print "TAAN:  " + taan.
print "TADN:  " + tadn.
set eoan to EccentricAnomalyFromTrueAnomaly(taan, orbit:eccentricity).
print "EoAN:  " + eoan.
set eodn to EccentricAnomalyFromTrueAnomaly(tadn, orbit:eccentricity).
print "EoDN:  " + eodn.
set moan to MeanAnomalyFromEccentricAnomaly(eoan, orbit:eccentricity).
print "MoAN:  " + moan.
set modn to MeanAnomalyFromEccentricAnomaly(eodn, orbit:eccentricity).
print "MoDN:  " + modn.

set secondsPerDegree to orbit:Period / 360.

set angleToApoapsis to BindAngleTo360(180 - mean).
set secondsToApoapsis to angleToApoapsis * secondsPerDegree.
set angleToPeriapsis to BindAngleTo360(360 - mean).
set secondsToPeriapsis to angleToPeriapsis * secondsPerDegree.
print "TTAP: " + TimeString(secondsToApoapsis).
print "TTPE: " + TimeString(secondsToPeriapsis).
set angleToAN to BindAngleTo360(moan - mean).
set secondsToAN to angleToAN * secondsPerDegree.
print "TTAN: " + TimeString(secondsToAN).
set angleToDN to BindAngleTo360(modn - mean).
set secondsToDN to angleToDN * secondsPerDegree.
print "TTDN: " + TimeString(secondsToDN).

print "".
wait 1.
}


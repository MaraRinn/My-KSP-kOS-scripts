parameter desiredPeriapsis.
parameter desiredApoapsis.
parameter ratioA.
parameter ratioB.

runoncepath("lib/orbital_mechanics").

for node in allnodes {
	remove node.
	}

set periapsisRadius to desiredPeriapsis + orbit:body:radius.
set apoapsisRadius to desiredApoapsis + orbit:body:radius.
set resonantApoapsisRadius to ResonantOrbit(periapsisRadius, apoapsisRadius, ratioA, ratioB).
set resonantApoapsis to resonantApoapsisRadius - orbit:body:radius.

set periapsisNode to AlterPeriapsis(desiredPeriapsis).
set periapsisOrbit to periapsisNode:orbit.

if orbit:apoapsis < desiredPeriapsis {
	// What used to be the apoapsis is now the periapsis
	set resonantNode to AlterPeriapsis(resonantApoapsis, periapsisOrbit, time:seconds + periapsisNode:ETA + 1).
	}
else {
	set resonantNode to AlterApoapsis(resonantApoapsis, periapsisOrbit, time:seconds + periapsisNode:ETA + 1).
	}
set resonantOrbit to resonantNode:orbit.
set resonantPeriod to resonantOrbit:period.

set deresonateNode to AlterApoapsis(desiredApoapsis, resonantOrbit, time:seconds + resonantNode:ETA + 1).
set stablePeriod to deresonateNode:orbit:period.

clearscreen.
print "Resonant Orbit Setup".
print "====================".
print "Periapsis: " + desiredPeriapsis + " (radius:" + periapsisRadius + ")".
print "Apoapsis:  " + desiredApoapsis + " (radius:" + apoapsisRadius + ")".
print " ".
print "Resonant Apoapsis: " + round(resonantApoapsis, 0) + " (radius:" + round(resonantApoapsisRadius, 0) + ")".
print " ".
print "Base Period:     " + round(stablePeriod, 0).
print "Resonant Period: " + round(resonantPeriod, 0).
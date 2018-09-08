parameter newPeriapsis is orbit:periapsis.
parameter newApoapsis is newPeriapsis.
parameter aop is orbit:argumentofperiapsis.

runoncepath("orbital_mechanics").

set nodeTime to time:seconds.
set newOrbit to orbit.

if (newPeriapsis <> orbit:periapsis) {
	set peNode to AlterPeriapsis(newPeriapsis, newOrbit, nodeTime).
	set newOrbit to peNode:orbit.
	set nodeTime to peNode:ETA + time:seconds.
	}

if (newApoapsis <> newOrbit:apoapsis) {
	set apNode to AlterApoapsis(newApoapsis, newOrbit, nodeTime).
	set newOrbit to apNode:orbit.
	set nodeTime to apNode:ETA + time:seconds.
	}

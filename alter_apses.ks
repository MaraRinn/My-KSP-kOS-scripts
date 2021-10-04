parameter newPeriapsis is orbit:periapsis.
parameter newApoapsis is newPeriapsis.
parameter newLAN is orbit:LAN.
parameter newAop is orbit:argumentofperiapsis.

runoncepath("lib/orbital_mechanics").

local alterApsesNodeTime is time:seconds.
local newOrbit is orbit.

if (newPeriapsis <> orbit:periapsis) {
	set peNode to AlterPeriapsis(newPeriapsis, newOrbit, alterApsesNodeTime).
	set newOrbit to peNode:orbit.
	set alterApsesNodeTime to peNode:ETA + time:seconds.
	}

if (newApoapsis <> newOrbit:apoapsis) {
	set apNode to AlterApoapsis(newApoapsis, newOrbit, alterApsesNodeTime).
	set newOrbit to apNode:orbit.
	set alterApsesNodeTime to apNode:ETA + time:seconds.
	}

if (newLAN <> newOrbit:LAN) {
	// How to adjust LAN?
}

if (newAop <> newOrbit:argumentOfPeriapsis) {
	// How to adjust AoP?
}

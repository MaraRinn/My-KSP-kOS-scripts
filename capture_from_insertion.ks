run orbital_mechanics.

// NB: This calculation would produce the required delta-V for capture
// The catch is that KSP has an arbitrary "Sphere of Influence" which is sometimes smaller than largest orbit

set velocityAtPeriapsis to VelocityAtR(body:radius + periapsis, orbit:semimajoraxis, body:mu).
print "VP: " + velocityAtPeriapsis.
set vesc to VelocityEscape(body:radius, body:mu).
print "Vesc: " + vesc.
set desiredSpeed to vesc * 0.99.
set deltaV to (velocityAtPeriapsis - desiredSpeed).
print "∆V: " + deltaV.

// calculate apoapsis from desiredSpeed and periapsis
set sma to SemiMajorAxisFromRadiusSpeedMu(periapsis+body:radius, desiredSpeed, body:mu).
set newApoapsis to 2 * sma - (periapsis + body:radius) - body:radius.
print "New Apoapsis: " + newApoapsis.
set kspSoiLimit to body:soiradius * 0.99 - body:radius.
print "SOI clamped: " + kspSoiLimit.
if newApoapsis > kspSoiLimit or newApoapsis < 0 {
	set newApoapsis to kspSoiLimit.
}
print "Using: " + newApoapsis.

AlterApoapsis(newApoapsis).

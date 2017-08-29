// Keep an equatorial relay in sync with Ike

print "Performing station keeping".
run orbital_mechanics.

function PrepareNode {
	declare parameter r.
	declare parameter desiredSMA.
	declare parameter nodeTime.
	set oldSpeed to sqrt(body:mu * (2/r - 1/orbit:SemiMajorAxis)).
	set newSpeed to sqrt(body:mu * (2/r - 1/desiredSMA)).
	set deltaSpeed to newSpeed - oldSpeed.
	if hasnode {
		print "Already has a manoeuvre node.".
		}
	else if deltaSpeed < 0.1 {
		print "Already adjusting position".
		set change to "Tidy".
		}
	else if nodeTime > 0 {
		print "Old speed: " + oldSpeed.
		print "New speed: " + newSpeed.
		print "∆V: " + deltaSpeed.
		print "Change at apoapsis: " + atApoapsis.
		set keepingNode to node(nodeTime, 0, 0, deltaSpeed).
		add keepingNode.
		}
	}

// it's a long story
set controlPart to ship:partsdubbedpattern("HECS2")[0].
controlPart:controlFrom().

// If we have no manoeuvre nodes, see if we need one
// Where are we, relative to Ike?
set shipVector to -duna:position.
set ikeVector to ike:position - duna:position.
set shipAngle to MeanAnomalyFromOrbit(ship:orbit).
set ikeAngle to MeanAnomalyFromOrbit(ike:orbit).
set angle to round(ikeAngle - shipAngle).
if angle < -180 { set angle to angle + 360. }
if angle > 180 { set angle to angle - 360. }
print "Angle: " + angle.
set desiredAngle to 120.
if angle < 0 { set desiredAngle to -120. }
print "Desired: " + desiredAngle.
set shipOrbitNormal to vcrs(ship:orbit:velocity:orbit, shipVector).
set shipTargetNormal to vcrs(shipVector, ikeVector).
set dotp to vdot(shipOrbitNormal, shipTargetNormal).
set following to false.
if dotp < 0 {
	print "Ike is ahead".
	set following to true.
	}
else {
	print "Ike is behind".
	}

set change to "None".
// If the angle is greater than 120°, phase closer.
if angle > 120 {
	set change to "Faster".
	}
else if angle < -120 {
	set change to "Slower".
	}
else if angle > 0 {
	set change to "Slower".
	}
else if angle < 0 {
	set change to "Faster".
	}
else {
	set change to "Tidy".
	}
print "Change mode: " + change.

// Determine the manoeuvre required
set desiredPeriod to Ike:Orbit:Period.
set r to orbit:SemiMajorAxis.
set desiredSMA to orbit:SemiMajorAxis.
set atApoapsis to false.
set nodeTime to 0.
if change = "Faster" {
	if orbit:period > Ike:Orbit:Period * (359/360) {
		set desiredSMA to ((359/360)^2)^(1/3) * Ike:Orbit:SemiMajorAxis.
		set atApoapsis to false.
		set r to periapsis + body:radius.
		set nodeTime to eta:periapsis + time:seconds.
		PrepareNode(r, desiredSMA, nodeTime).
		}
	}
else if change = "Slower" {
	if orbit:period < Ike:Orbit:Period * (361/360) {
		set desiredSMA to ((361/360)^2)^(1/3) * Ike:Orbit:SemiMajorAxis.
		set atApoapsis to true.
		set r to apoapsis + body:radius.
		set nodeTime to eta:apoapsis + time:seconds.
		PrepareNode(r, desiredSMA, nodeTime).
		}
	}

if change = "Tidy" {
	set wT to (360/Ike:Orbit:Period).
	set wS to (360/Orbit:Period).
	set dw to wT - wS.
	set phasingTime to (desiredAngle-angle) / dw.
	set phasingOrbits to ceiling(phasingTime / Orbit:Period).
	print "Phasing Orbits: " + phasingOrbits.
	// Alter orbital period to be exactly the same as Ike's
	// if orbit period is exactly Ike's and eccentricity is < 0.01, do nothing. Otherwise:
	// Which is closer: apoapsis or periapsis?
		// at apoapsis, plan to raise periapsis a tiny bit (a few tens of seconds)
		// at periapsis, plan to lower apoapsis a tiny bit
	}

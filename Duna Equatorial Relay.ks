// Keep an equatorial relay in sync with Ike

print "Performing station keeping".
runoncepath("lib/orbital_mechanics").

function PrepareNode {
	declare parameter newR.
	declare parameter newSMA.
	declare parameter nextNodeTime.
	set oldSpeed to sqrt(body:mu * (2/newR - 1/orbit:SemiMajorAxis)).
	set newSpeed to sqrt(body:mu * (2/newR - 1/newSMA)).
	set deltaSpeed to newSpeed - oldSpeed.
	if hasnode {
		print "Already has a manoeuvre node.".
		}
	else if deltaSpeed < 0.1 {
		print "Already adjusting position".
		set change to "Tidy".
		}
	else if nextNodeTime > 0 {
		print "Old speed: " + oldSpeed.
		print "New speed: " + newSpeed.
		print "∆V: " + deltaSpeed.
		print "Change at apoapsis: " + atApoapsis.
		set keepingNode to node(nextNodeTime, 0, 0, deltaSpeed).
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
declare angleIkeShip is round(ikeAngle - shipAngle).
if angleIkeShip < -180 { set angleIkeShip to angleIkeShip + 360. }
if angleIkeShip > 180 { set angleIkeShip to angleIkeShip - 360. }
print "Angle: " + angleIkeShip.
set desiredAngle to 120.
if angleIkeShip < 0 { set desiredAngle to -120. }
print "Desired: " + desiredAngle.
set shipOrbitNormal to vcrs(ship:orbit:velocity:orbit, shipVector).
set shipTargetNormal to vcrs(shipVector, ikeVector).
set dotp to vdot(shipOrbitNormal, shipTargetNormal).
if dotp < 0 {
	print "Ike is ahead".
	}
else {
	print "Ike is behind".
	}

set change to "None".
// If the angle is greater than 120°, phase closer.
if angleIkeShip > 120 {
	set change to "Faster".
	}
else if angleIkeShip < -120 {
	set change to "Slower".
	}
else if angleIkeShip > 0 {
	set change to "Slower".
	}
else if angleIkeShip < 0 {
	set change to "Faster".
	}
else {
	set change to "Tidy".
	}
print "Change mode: " + change.

// Determine the manoeuvre required
set desiredSMA to orbit:SemiMajorAxis.
set atApoapsis to false.
set relayNodeTime to 0.
if change = "Faster" {
	if orbit:period > Ike:Orbit:Period * (359/360) {
		set desiredSMA to ((359/360)^2)^(1/3) * Ike:Orbit:SemiMajorAxis.
		set atApoapsis to false.
		set periapsisRadius to periapsis + body:radius.
		set relayNodeTime to eta:periapsis + time:seconds.
		PrepareNode(periapsisRadius, desiredSMA, relayNodeTime).
		}
	}
else if change = "Slower" {
	if orbit:period < Ike:Orbit:Period * (361/360) {
		set desiredSMA to ((361/360)^2)^(1/3) * Ike:Orbit:SemiMajorAxis.
		set atApoapsis to true.
		set r to apoapsis + body:radius.
		set relayNodeTime to eta:apoapsis + time:seconds.
		PrepareNode(r, desiredSMA, relayNodeTime).
		}
	}

if change = "Tidy" {
	set wT to (360/Ike:Orbit:Period).
	set wS to (360/Orbit:Period).
	set dw to wT - wS.
	set phasingTime to (desiredAngle-angleIkeShip) / dw.
	set phasingOrbits to ceiling(phasingTime / Orbit:Period).
	print "Phasing Orbits: " + phasingOrbits.
	// Alter orbital period to be exactly the same as Ike's
	// if orbit period is exactly Ike's and eccentricity is < 0.01, do nothing. Otherwise:
	// Which is closer: apoapsis or periapsis?
		// at apoapsis, plan to raise periapsis a tiny bit (a few tens of seconds)
		// at periapsis, plan to lower apoapsis a tiny bit
	}

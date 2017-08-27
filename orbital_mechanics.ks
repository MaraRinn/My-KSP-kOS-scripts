// Calculate required velocity at apoapsis (or periapsis) for circular orbit

function create_circularise_node {
	declare parameter isApoapsis is true.

	// For circular orbit, µ = rv^2
	// So v = sqrt(µ/r)
	if isApoapsis {
		set r to body:radius + ship:apoapsis.
		}
	else {
		set r to body:radius + ship:periapsis.
		}
	set required_velocity_magnitude to sqrt(body:mu/r).

	// Estimate speed of this ship at APOAPSIS
	// https://gaming.stackexchange.com/questions/144030/how-do-i-calculate-necessary-delta-v-for-circularization-burn

	set semi_major to (SHIP:APOAPSIS + SHIP:PERIAPSIS) / 2 + BODY:RADIUS.
	set orbit_speed to sqrt(body:mu * (2/r - 1/semi_major)).

	// Create manoeuvre node at apoapsis

	set dR to 0.
	set dN to 0.
	set dP to required_velocity_magnitude - orbit_speed.
	if isApoapsis {
		set nodeTime to eta:apoapsis + time:seconds.
		}
	else {
		set nodeTime to eta:periapsis + time:seconds.
		}

	set circularisation to node(nodeTime,dR, dN, dP).
	add circularisation.
}

function SemiMajorFromPeriod {
	declare parameter period.
	declare parameter centreBody is body.
	
	set semiMajorAxis to ((period^2 * centreBody:mu) / (4 * constant:pi^2))^(1/3).
	return semiMajorAxis.
	}

function EccentricAnomalyFromMeanAnomaly {
	declare parameter meanAnomaly.
	declare parameter eccentricity.
	
	set eccentricAnomaly to meanAnomaly + eccentricity * sin(meanAnomaly).
	lock checkM to eccentricAnomaly - eccentricity * sin(eccentricAnomaly).
	lock deltaE to
		(eccentricAnomaly - eccentricity * sin(eccentricAnomaly) - meanAnomaly)
		/
		(1 - eccentricity * cos(eccentricAnomaly)).
	until deltaE < 0.000005 {
		set eccentricAnomaly to eccentricAnomaly - deltaE.
		}
	return eccentricAnomaly.
	}

function MeanAnomalyFromOrbit {
	declare parameter orbitOfInterest.
	set orbitPeriod to orbitOfInterest:period.
	set secondsSinceEpoch to time:seconds - orbitOfInterest:epoch.
	set totalOrbits to secondsSinceEpoch / orbitPeriod.
	set orbitFraction to totalOrbits - floor(totalOrbits).
	return orbitFraction * 360 + orbitOfInterest:meanAnomalyAtEpoch.
	}

function MeanAnomalyFromEccentricAnomaly {
	declare parameter eccentricAnomaly.
	declare parameter eccentricity.

	set meanAnomaly to eccentricAnomaly - eccentricity * sin(eccentricAnomaly).
	return meanAnomaly.
	}

function TrueAnomalyFromEccentricAnomaly {
	declare parameter eccentricAnomaly.
	declare parameter eccentricity.

	set x to sqrt(1 - eccentricity) * cos(eccentricAnomaly / 2).
	set y to sqrt(1 + eccentricity) * sin(eccentricAnomaly / 2).
	set theta to 2 * atan2(y, x).
	}

function EccentricAnomalyFromTrueAnomaly {
	declare parameter trueAnomaly.
	declare parameter eccentricity.

	set cosArgument to (eccentricity + cos(trueAnomaly)) / (1 + eccentricity * cos(trueAnomaly)).
	set sinArgument to (sqrt(1 - eccentricity^2) * sin(trueAnomaly)) / (1 + eccentricity * cos(trueAnomaly)).
	set fromCos to ArcCos(cosArgument).
	print "From Cosine: " + round(fromCos, 3).
	set fromSin to ArcSin(sinArgument).
	print "From Sine:   " + round(fromSin, 3).
	print "Other Sine:  " + round((180 - fromSin), 3).
	set fromTan to ArcTan(sinArgument / cosArgument).
	print "From Tan:    " + round(fromTan, 3).
	set otherTan to ArcTan2(-sinArgument, cosArgument).
	print "Other Tan:   " + round(otherTan, 3).
	if trueAnomaly > 180 {
		set otherTan to 360 - otherTan.
		}
	return otherTan.
	}

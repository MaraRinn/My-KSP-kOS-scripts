function VelocityAtR {
	declare parameter r.
	declare parameter semiMajorAxis.
	declare parameter mu.

	set orbitSpeed to sqrt(mu * (2/r - 1/semiMajorAxis)).
	return orbitSpeed.
	}

function VelocityEscape {
	declare parameter r.
	declare parameter mu.
	set escapeVelocity to sqrt((2 * mu)/r). // Ve = root(2GM/r)
	return escapeVelocity.
	}

function PeriodFromSemiMajorAxis {
	declare parameter a.
	declare parameter mu is body:mu.
	set period to 2 * constant:Pi * sqrt(a^3 / mu).
	return period.
	}

function SemiMajorAxisFromPeriod {
	declare parameter period.
	declare parameter mu is body:mu.
	set twoPi to 2 * constant:Pi.
	set a to (mu * (period/twoPi)^2)^(1/3).
	return a.
	}

function SemiMajorAxisFromRadiusSpeedMu {
	declare parameter radius.
	declare parameter speed.
	declare parameter mu.

	set derivedSMA to 1/(2/radius - speed^2/mu).
	return derivedSMA.
	}

function SpeedFromSemiMajorAxisRadiusMu {
	declare parameter sma.
	declare parameter radius.
	declare parameter mu.
	
	set derivedSpeed to sqrt(mu * (2/radius - 1/sma)).
	return derivedSpeed.
	}

function FuelMassFromDeltaVEndMass {
	declare parameter DeltaV.
	declare parameter EndMass.
	
	}

function BindAngleTo360 {
	declare parameter angle.

	until angle >= 0 {
		set angle to angle + 360.
		}

	until angle < 360 {
		set angle to angle - 360.
		}

	return angle.
}

function TimeString {
	declare parameter secondsToDisplay.
	
	set daysValue to floor(secondsToDisplay / (3600 * 6)).
	set afterDays to secondsToDisplay - (daysValue * 3600 * 6).
	set hoursValue to floor(afterDays / 3600).
	set afterHours to afterDays - (hoursValue * 3600).
	set minutesValue to floor(afterHours / 60).
	set seconds to floor(afterHours - (minutesValue * 60)).
	return daysValue + "d " + hoursValue + "h " + minutesValue + "m " + seconds + "s".
	}

function TimeToNearestNode {
	declare parameter myOrbit is Orbit.

	set celestialLongitude to LongitudeFromOrbit(myOrbit).
	set lan to myOrbit:LongitudeOfAscendingNode.
	if lan > 180 {
		set ldn to lan - 180.
		}
	else {
		set ldn to lan + 180.
		}
	}

function TimeToHighestNode {
	declare parameter myOrbit is Orbit.

	set celestialLongitude to LongitudeFromOrbit(myOrbit).
	if myOrbit:ArgumentOfPeriapsis > 90 and myOrbit:ArgumentOfPeriapsis < 270 {
		set longitudeOfNode to myOrbit:LongitudeOfAscendingNode.
		}
	else if myOrbit:LongitudeOfAscendingNode >= 180 {
		set longitudeOfNode to myOrbit:LongitudeOfAscendingNode - 180.
		}
	else {
		set longitudeOfNode to myOrbit:LongitudeOfAscendingNode + 180.
		}
	if longitudeOfNode < celestialLongitude {
		set longitudeOfNode to longitudeOfNode + 360.
		}
	set angleToNode to longitudeOfNode - celestialLongitude.
	set secondsPerDegree to myOrbit:Period / 360.
	set timeToNode to angleToNode * secondsPerDegree.
	return timeToNode.
	}

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

function AlterApoapsis {
	parameter newApoapsis.
	parameter myOrbit is Orbit.
	parameter timeOfInterest is time:seconds.
	parameter maximumBurnTime is 0.

	set oldPeriapsisRadius to Orbit:Periapsis + Orbit:Body:Radius.
	set oldSemiMajorAxis to Orbit:SemiMajorAxis.
	set oldOrbitSpeedAtPeriapsis to velocityAtR(oldPeriapsisRadius, oldSemiMajorAxis, Orbit:Body:Mu).

	set newSemiMajorAxis to (Orbit:Periapsis + newApoapsis)/2 + Orbit:Body:Radius.
	set newOrbitSpeedAtPeriapsis to velocityAtR(oldPeriapsisRadius, newSemiMajorAxis, Orbit:Body:Mu).

	set deltaV to newOrbitSpeedAtPeriapsis - oldOrbitSpeedAtPeriapsis.
	if myOrbit = Orbit {
		set timeToPeriapsis to ETA:Periapsis.
		}
	else {
		set angleToPeriapsis to 360 - MeanAnomalyFromOrbit(myOrbit, timeOfInterest).
		if angleToPeriapsis < 0 {
			set angleToPeriapsis to angleToPeriapsis + 360.
			}
		set timeToPeriapsis to angleToPeriapsis * (myOrbit:Period / 360).
		}
	set nodeTime to timeToPeriapsis + timeOfInterest.
	set newNode to node(nodeTime, 0, 0, deltaV).
	add newNode.
	return newNode.
	}

function AlterPeriapsis {
	parameter newPeriapsis.
	parameter myOrbit is Orbit.
	parameter timeOfInterest is time:seconds.

	set oldApoapsisRadius to myOrbit:Apoapsis + myOrbit:Body:Radius.
	set oldSemiMajorAxis to myOrbit:SemiMajorAxis.
	set oldOrbitSpeedAtApoapsis to velocityAtR(oldApoapsisRadius, oldSemiMajorAxis, myOrbit:Body:Mu).

	set newSemiMajorAxis to (myOrbit:Apoapsis + newPeriapsis)/2 + myOrbit:Body:Radius.
	set newOrbitSpeedAtApoapsis to velocityAtR(oldApoapsisRadius, newSemiMajorAxis, myOrbit:Body:Mu).

	set deltaV to newOrbitSpeedAtApoapsis - oldOrbitSpeedAtApoapsis.
	set angleToApoapsis to 180 - MeanAnomalyFromOrbit(myOrbit, timeOfInterest).
	if angleToApoapsis < 0 {
		set angleToApoapsis to angleToApoapsis + 360.
		}
	set timeToApoapsis to angleToApoapsis * (myOrbit:Period / 360).
	set nodeTime to timeToApoapsis + timeOfInterest.
	set newNode to node(nodeTime, 0, 0, deltaV).
	add newNode.
	return newNode.
	}

function AlterSMA {
	parameter newA.
	parameter oldOrbit is Orbit.
	parameter timeOfInterest is time:seconds.
	
	print "Old SMA: " + oldOrbit:SemiMajorAxis.
	print "New SMA: " + newA.

	if newA < oldOrbit:SemiMajorAxis {
		// Lower the apoapsis
		set newApoapsis to 2 * newA - oldOrbit:periapsis - (2 * oldOrbit:body:radius).
		print "New Ap: " + newApoapsis.
		set newNode to AlterApoapsis(newApoapsis, oldOrbit, timeOfInterest).
		}
	else {
		// Raise the periapsis
		set newPeriapsis to 2 * newA - oldOrbit:apoapsis - (2 * oldOrbit:body:radius).
		print "New Pe: " + newPeriapsis.
		set newNode to AlterPeriapsis(newPeriapsis, oldOrbit, timeOfInterest).
		}
	return newNode.
	}

function AlterInclination {
	parameter newInclination.
	parameter atHighestNode is true. // highest ¬nearest

	set taan to TrueAnomalyOfAscendingNode().
	set tadn to TrueAnomalyOfDescendingNode().
	set ttdn to TimeToDescendingNode().
	set ttan to TimeToAscendingNode().
	set nodeEta to 0.

	if not atHighestNode {
		// Use closest node
		if ttdn < ttan {
			print " - DN is closer".
			set timeToNode to ttdn.
			set newInclination to -newInclination.
			}
		else {
			print " - AN is closer".
			set timeToNode to ttan.
			}
		}
	else {
		// Use highest node
		if orbit:ArgumentOfPeriapsis < 90 or orbit:ArgumentOfPeriapsis > 270 {
			print " - DN is higher".
			set timeToNode to ttdn.
			set newInclination to -newInclination.
			}
		else {
			print " - AN is higher".
			set timeToNode to ttan.
			}
		}

	set vx to VelocityAt(ship, time:seconds + timeToNode):orbit:mag.
	print " - vx = " + vx.
	set dTheta to (newInclination - orbit:inclination).
	//set dv to sqrt(2 * vx^2 * (1 - cos(dTheta))).
	set dv to vx * sin(dTheta/2).
	print " - dv = " + dv.
	set Vn to cos(dTheta) * dv.
	set Vp to -abs(sin(dTheta) * dv).
	set node to node(time:seconds + timeToNode, 0, Vn, Vp).
	add node.
	}

function LongitudeFromOrbit {
	parameter orbitOfInterest.
	
	set lan to orbitOfInterest:lan.
	set argumentofPeriapsis to orbitOfInterest:ArgumentOfPeriapsis.
	set meanAnomaly to MeanAnomalyFromOrbit(orbitOfInterest).
	
	set theLongitude to LongitudeFromMeanAnomaly(lan, argumentOfPeriapsis, meanAnomaly).
	return theLongitude.
	}

function TrueAnomalyOfAscendingNode {
	declare parameter myOrbit is orbit.

	set taan to (360 - myOrbit:ArgumentOfPeriapsis).
	return taan.
	}

function MeanAnomalyOfAscendingNode {
	declare parameter myOrbit is orbit.
	
	set taan to TrueAnomalyOfAscendingNode(myOrbit).
	set eaan to EccentricAnomalyFromTrueAnomaly(taan, orbit:eccentricity).
	set maan to MeanAnomalyFromEccentricAnomaly(eaan, orbit:eccentricity).
	return maan.
	}

function TimeToAscendingNode {
	declare parameter myOrbit is orbit.
	set secondsPerDegree to myOrbit:Period / 360.

	set mean to MeanAnomalyFromOrbit(myOrbit).
	set maan to MeanAnomalyOfAscendingNode(myOrbit).
	set angle to BindAngleTo360(maan - mean).
	set secondsToAN to angle * secondsPerDegree.
	return secondsToAn.
	}

function TrueAnomalyOfDescendingNode {
	declare parameter myOrbit is orbit.

	set tadn to BindAngleTo360(180 - myOrbit:ArgumentOfPeriapsis).
	return tadn.
	}

function MeanAnomalyOfDescendingNode {
	declare parameter myOrbit is orbit.

	set tadn to TrueAnomalyOfDescendingNode(myOrbit).
	set eadn to EccentricAnomalyFromTrueAnomaly(tadn, orbit:eccentricity).
	set madn to MeanAnomalyFromEccentricAnomaly(eadn, orbit:eccentricity).
	return madn.
	}

function TimeToDescendingNode {
	declare parameter myOrbit is orbit.
	set secondsPerDegree to myOrbit:Period / 360.

	set mean to MeanAnomalyFromOrbit(myOrbit).
	set madn to MeanAnomalyOfDescendingNode(myOrbit).
	set angle to BindAngleTo360(madn - mean).
	set secondsToDN to angle * secondsPerDegree.
	return secondsToDN.
	}

function EccentricAnomalyFromMeanAnomaly {
	declare parameter meanAnomaly.
	declare parameter eccentricity.
	
	set eccentricAnomaly to 180.
	lock checkM to eccentricAnomaly - eccentricity * sin(eccentricAnomaly).
	lock deltaE to
		(eccentricAnomaly - eccentricity * sin(eccentricAnomaly) * Constant:RadToDeg - meanAnomaly)
		/
		(1 - eccentricity * cos(eccentricAnomaly)).
	until abs(deltaE) < 0.000005 {
		set eccentricAnomaly to eccentricAnomaly - deltaE.
		}
	return eccentricAnomaly.
	}

function EccentricAnomalyFromTrueAnomaly {
	declare parameter trueAnomaly.
	declare parameter eccentricity.

	set cosArgument to eccentricity + cos(trueAnomaly).
	set sinArgument to sqrt(1 - eccentricity^2) * sin(trueAnomaly).
	set fromTan to ArcTan2(sinArgument, cosArgument).
	if sinArgument < 0 {
		set fromTan to fromTan + 360.
		}
	return fromTan.
	}

function LongitudeFromMeanAnomaly {
	declare parameter lan.
	declare parameter argumentOfPeriapsis.
	declare parameter meanAnomaly.
	
	set rawLongitude to lan + argumentOfPeriapsis + meanAnomaly.
	set theLongitude to rawLongitude - (floor(rawLongitude / 360) * 360).
	if theLongitude > 180 {
		set theLongitude to theLongitude - 360.
		}
	return theLongitude.
	}

function MeanAnomalyFromOrbit {
	parameter orbitOfInterest.
	parameter timeOfInterest is time:seconds.
	set orbitPeriod to orbitOfInterest:period.
	set secondsSinceEpoch to timeOfInterest - orbitOfInterest:epoch.
	set totalOrbits to secondsSinceEpoch / orbitPeriod.
	set orbitFraction to totalOrbits - floor(totalOrbits).
	return orbitFraction * 360 + orbitOfInterest:meanAnomalyAtEpoch.
	}

function MeanAnomalyFromPeriodEpochAngleTime {
	parameter period.
	parameter epoch is 0.
	parameter meanAnomalyAtEpoch is 0.
	parameter timeOfInterest is time:seconds.

	set secondsSinceEpoch to timeOfInterest - epoch.
	set totalOrbits to secondsSinceEpoch / period.
	set orbitFraction to totalOrbits - floor(totalOrbits).
	set meanAnomaly to orbitFraction * 360 + meanAnomalyAtEpoch.
	if meanAnomaly > 360 { set meanAnomaly to meanAnomaly - 360. }
	return meanAnomaly.
	}

function MeanAnomalyFromEccentricAnomaly {
	declare parameter eccentricAnomaly.
	declare parameter eccentricity.

	set meanAnomaly to eccentricAnomaly - eccentricity * sin(eccentricAnomaly) * constant:RadToDeg.
	return meanAnomaly.
	}

function TrueAnomalyFromEccentricAnomaly {
	declare parameter eccentricAnomaly.
	declare parameter eccentricity.

	set cosArgument to sqrt(1 - eccentricity) * cos(eccentricAnomaly / 2).
	set sinArgument to sqrt(1 + eccentricity) * sin(eccentricAnomaly / 2).
	set theta to 2 * arctan2(sinArgument, cosArgument).
	if sinArgument < 0 {
		set theta to theta + 360.
		}
	return theta.
	}

function H {
	declare parameter Q.
	declare parameter R.

	declare P is list(0,0,0,0).
	set P[0] to R[0]*Q[0] - R[1]*Q[1] - R[2]*Q[2] - R[3]*Q[3].
   set P[1] to R[0]*Q[1] + R[1]*Q[0] - R[2]*Q[3] + R[3]*Q[2].
   set P[2] to R[0]*Q[2] + R[1]*Q[3] + R[2]*Q[0] - R[3]*Q[1].
   set P[3] to R[0]*Q[3] - R[1]*Q[2] + R[2]*Q[1] + R[3]*Q[0].
   return P.
	}

function VectorToQuaternion {
	declare parameter vector.
	set Q to list (0, vector:x, vector:y, vector:z).
	return Q.
	}

function QuaternionToVector {
	declare parameter Q.
	set vector to V(Q[1], Q[2], Q[3]).
	return vector.
	}

function RotationQuaternion {
	declare parameter rotationAngleDegrees.
	declare parameter axis.
	set Q to list(
		cos(rotationAngleDegrees/2),
		sin(rotationAngleDegrees/2) * axis:x,
		sin(rotationAngleDegrees/2) * axis:y,
		sin(rotationAngleDegrees/2) * axis:z
		).
	return Q.
	}

function InverseQuaternion {
	declare parameter quaternion.
	return list(
		quaternion[0],
		-quaternion[1],
		-quaternion[2],
		-quaternion[3]
		).
	}

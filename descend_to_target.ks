run orbital_mechanics.
run "lib/utility".

// Assumptions:
// 1. Target is on the equator
// 2. The surface has no obstructions (the target is not down a hole)
// 3. Orbit is circular

set done to false.

on ABORT {
	preserve.
	set done to true.
	}

function FitToLongitude {
	parameter l.
	until l <= 180 {
		set l to l - 360.
		}
	until l >= -180 {
		set l to l + 360.
		}
	return l.
	}

function DisplayValues {
	parameter display_lexicon.
	set maxLabelWidth to 0.
	set maxDataWidth to 0.
	set row to 1.
	for item in display_lexicon:keys {
		set itemString to item:ToString.
		if itemString:length > maxLabelWidth { set maxLabelWidth to itemString:length. }
		set valueString to display_lexicon[item]:ToString.
		if valueString:length > maxDataWidth {
			set maxDataWidth to valueString:length.
			}
		}
	for item in display_lexicon:keys {
		set itemString to item:ToString.
		set valueString to display_lexicon[item]:ToString.
		print itemString:PadRight(maxLabelWidth) + "  " + valueString:PadLeft(maxDataWidth) at (0,row).
		set row to row + 1.
		}
	}

set calculations to Lexicon().

// Procedure
// 1. Estimate period of orbit given apoapsis in current orbit, periapsis above target
set newPeriapsis to body:radius + max(target:altitude + 200, terrainHeight()).
set newSMA to (body:radius + orbit:Apoapsis + newPeriapsis)/2.
set newPeriod to PeriodFromSemiMajorAxis(newSMA).
set calculations["New Periapsis"] to round(newPeriapsis, 0).
set calculations["New SMA"] to round(newSMA, 0).

// 2. Descent time is half that orbital period
set descentTime to newPeriod/2.

// 3. Estimate angle traversed by target due to body's rotation in the descent time
set targetSweep to (360 * descentTime) / body:rotationperiod.

// 4. This gives us the angle required between the ship and the target at which to begin the descent (remembering we're landing at the other side of this ship's orbit)
set descentOffset to -FitToLongitude(180-targetSweep).

// 5. Determine the time required for the ship to get into the right position relative to the target (based on angular velocity of target and ship, compared to current angular separation and required angular separation, negative means the landing site is moving faster)
set closingRate to 360 / ship:orbit:period - 360 / body:rotationperiod.
set targetLongitude to body:GeoPositionOf(target:position):Lng.
set shipLongitude to body:GeoPositionOf(ship:position):Lng.
set currentOffset to FitToLongitude(shipLongitude - targetLongitude).
set remainingOffset to descentOffset - currentOffset.
if closingRate > 0 {
	// vessel is closing with landing site
	if remainingOffset < 0 {
		set remainingOffset to remainingOffset + 360.
		}
	}
else {
	// landing site is faster than vessel
	if remainingOffset > 0 {
		set remainingOffset to remainingOffset - 360.
		}
	}
set manoeuvreEta to remainingOffset / closingRate.
set radiusAtNode to (PositionAt(ship, time:seconds + manoeuvreEta) - body:position):mag.
set velocityAtNode to SpeedFromSemiMajorAxisRadiusMu(orbit:semimajoraxis, radiusAtNode, body:mu).
set calculations["Velocity at Node"] to velocityAtNode.
set newVelocityAtNode to SpeedFromSemiMajorAxisRadiusMu(newSMA, radiusAtNode, body:mu).
set calculations["New Velocity At Node"] to newVelocityAtNode.
set manoeuvreDeltaV to newVelocityAtNode - velocityAtNode.

clearscreen.
set calculations["New SMA"] to round(newSMA, 0).
set calculations["Descent Time"] to round(descentTime, 0).
set calculations["Target Sweep"] to round(targetSweep, 2).
set calculations["Descent Offset"] to round(descentOffset, 1).
set calculations["Remaining Offset"] to round(remainingOffset, 1).
set calculations["Closing Rate"] to round(closingRate, 3) + "°/s".
set calculations["Current Offset"] to round(currentOffset, 1).
set calculations["Manoeuvre ETA"] to round(manoeuvreEta, 1).
set calculations["Manoeuvre ∆V"] to round(manoeuvreDeltaV, 1).
DisplayValues(calculations).
// 6. Schedule a manoeuvre node at that time in the future, with the delta-V required to get into the target orbit
set dR to 0.
set dN to 0.
set dP to manoeuvreDeltaV.
set nodeTime to time:seconds + manoeuvreEta.
set descentNode to node(nodeTime, dR, dN, dP).
add descentNode.
sas off.
run "execute_next_node".

// 7. Verify that the ship passes over the target at/near periapsis

// 8. Schedule a braking manoeuvre to bring the vessel to a halt over the target

set maximumAcceleration to maxthrust/mass.
set periapsisTime to time:seconds + eta:periapsis.
set approachVelocity to velocityAt(ship, periapsisTime):surface:mag.
set brakingTime to approachVelocity/maximumAcceleration.
warpto(periapsisTime - brakingTime - 20).
runpath("brake_at_approach").

// 9. Enter hover over the target

// 10. If a link port is the selected target, and the current vessel has a link port, rotate and translate the craft to get the two ports facing each other

// 11. Land

// FIXME: Add plane change where required.


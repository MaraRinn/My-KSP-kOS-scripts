Parameter OrbitAltitude is 0.
Parameter AccelerationCap is 30. // m/s maximum acceleration
Parameter DrawVectors is false.

runoncepath("orbital_mechanics.ks").
runpath("lib/vessel_operations.ks").

set LaunchGuidanceParameters to Lexicon().

function ThrottleCapMethod {
	if not (defined MaxThrust) or (MaxThrust = 0) { return 0. }
	return AccelerationCap * Mass / MaxThrust.
	}
set ThrottleCapDelegate to ThrottleCapMethod@.
lock ThrottleCap to ThrottleCapDelegate:Call.

function ConfigureCTTAThrottleGuidance {
	parameter ThrottlePID.
	parameter TargetTimeToApoapsis is 50.

	set ThrottlePID:SetPoint to TargetTimeToApoapsis.
	}

function ThrottleGuidanceConstantTimeToApoapsis {
	parameter TargetApoapsisETA.

	set ThrottlePID:MaxOutput to ThrottleCap.
	set ThrottlePID:SetPoint to TargetApoapsisETA.
	return ThrottlePID:Update(time:seconds, eta:apoapsis).	
	}
set ThrottlePID to pidloop(1,0,0,0,ThrottleCap).
set ThrottleIntent to 0.


function ConfigureCTTAPitchGuidance {
	parameter PitchGuidancePID.
	parameter TargetTimeToApoapsis is 50.

	set PitchGuidancePID:SetPoint to TargetTimeToApoapsis.
	}

function PitchGuidanceConstantTimeToApoapsis {
	parameter TargetApoapsisETA.

	set PitchGuidancePID:SetPoint to TargetApoapsisETA.
	return PitchGuidancePID:Update(time:seconds, eta:apoapsis).
	}
set PitchGuidancePID to pidloop(1,0,-1,-30,30).
set AoAIntent to 0.

SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0. // Stop throttle resetting to 50%
set AtmosphereAltitude to BODY:ATM:HEIGHT.
set MinimumPeriapsis to max(AtmosphereAltitude, TerrainHeight()) + 1.
if not(defined OrbitAltitude) or (OrbitAltitude < MinimumPeriapsis) { set OrbitAltitude to MinimumPeriapsis + 500. }
lock LocalG to (body:mu / (body:radius + ship:altitude)^2).

// Vessel Specific Variables
if not (defined LaunchPitch) { set LaunchPitch to 80. }
if not (defined LaunchTimeToApoapsis) { set LaunchTimeToApoapsis to 50. }


// Prepare for launch
set SteeringIntent to up.
lock steering to SteeringIntent.
if not(defined LaunchGuidanceSkipStages) { set LaunchGuidanceSkipStages to 0. }
set LaunchGuidanceParameters["Skip Stages"] to LaunchGuidanceSkipStages.
set LaunchGuidanceParameters["Stage Count"] to 0.

// FIXME look for launch clamps and stage them too.
WHEN not (defined MaxThrust) or (MaxThrust = 0) THEN {
	stage.
	set LaunchGuidanceParameters["Stage Count"] to LaunchGuidanceParameters["Stage Count"] + 1.
	preserve.
	}

wait until MaxThrust > 0.

ConfigureCTTAThrottleGuidance(ThrottlePID, LaunchTimeToApoapsis).
ConfigureCTTAPitchGuidance(PitchGuidancePID, LaunchTimeToApoapsis).

print "Intended Apoapsis: " + OrbitAltitude.
print "Intended TTA:      " + LaunchTimeToApoapsis.
print "Minimum Periapsis: " + MinimumPeriapsis.

set runmode to "lift off".
set old_runmode to "".
lock Throttle to ThrottleIntent.

function CalculatePitchIntentVector {
	parameter AngleOfAttack.

	set progradeVector to velocity:surface.
	set pitchAxis to VectorCrossProduct(up:foreVector, progradeVector).
	set alteredProgradeVector to RotateVector(progradeVector, AngleOfAttack, pitchAxis).
	return alteredProgradeVector.
	}

if DrawVectors {
	set ProgradeArrow to VecDraw(V(0,0,0), {return velocity:surface.}, YELLOW, "Velocity", 1, true, 1).
	set PitchIntentArrow to VecDraw(V(0,0,0), {return CalculatePitchIntentVector(AoAIntent).}, GREEN, "Intent", 1, true, 1).
	set ForwardArrow to VecDraw(V(0,0,0), {return ship:facing:forevector:normalized * 50.}, BLUE, "", 1, true, 1).
	}

until runmode = "finished" {
	if not(old_runmode = runmode) {
		print "Runmode: " + runmode.
		set old_runmode to runmode.
		}
	if runmode = "lift off" {
		if (ship:velocity:surface:mag > LocalG * 20) { set runmode to "enter gravity turn". }
		set SteeringIntent to Heading(90, LaunchPitch).
		set ThrottleIntent to ThrottleCap.
		}
	if runmode = "enter gravity turn" {
		wait until MaxThrust > 0.
		set ThrottleIntent to ThrottleCap.
		set SteeringIntent to Velocity:Surface.
		set TTAConverged to (ABS(LaunchTimeToApoapsis - eta:apoapsis) < 1).
		if (LaunchGuidanceParameters["Stage Count"] >= LaunchGuidanceParameters["Skip Stages"]) and TTAConverged { set runmode to "gravity turn". }
		}
	if runmode = "gravity turn" {
		wait until MaxThrust > 0.
		set ThrottleIntent to ThrottleGuidanceConstantTimeToApoapsis(LaunchTimeToApoapsis).
		set AoAIntent to PitchGuidanceConstantTimeToApoapsis(LaunchTimeToApoapsis).
		set SteeringIntent to CalculatePitchIntentVector(AoAIntent).
		print "PI: " + round(AoAIntent) + "      " at (0, 20).
		if (Apoapsis >= OrbitAltitude) or (ThrottleIntent < 0.2) { set runmode to "maintain apoapsis". }
		}
	if (runmode = "maintain apoapsis") {
		wait until MaxThrust > 0.
		if (Altitude > MinimumPeriapsis) { set runmode to "finished". }
		set apoapsis_error to max(0, OrbitAltitude - Apoapsis) / OrbitAltitude.
		set ThrottleIntent to ship:velocity:orbit:mag * apoapsis_error / maxthrust * mass.
		set SteeringIntent to ship:velocity:orbit.
		}
	}

ClearVecDraws().
set ThrottleIntent to 0.
unlock all.
print "Ascent completed.".
create_circularise_node().
ExecuteNextNode().

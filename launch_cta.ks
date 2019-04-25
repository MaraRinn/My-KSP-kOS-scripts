Parameter OrbitAltitude is 0.
Parameter AccelerationCap is 30. // m/s maximum acceleration

runoncepath("orbital_mechanics.ks").
runpath("lib/vessel_operations.ks").

set LaunchGuidanceParameters to Lexicon().

function ThrottleCapMethod {
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

set ThrottlePID to pidloop(1,0,0,0,ThrottleCap).
set ThrottleIntent to 0.

ConfigureCTTAThrottleGuidance(ThrottlePID, LaunchTimeToApoapsis).

print "Intended Apoapsis: " + OrbitAltitude.
print "Intended TTA:      " + LaunchTimeToApoapsis.
print "Minimum Periapsis: " + MinimumPeriapsis.

set runmode to "lift off".
set old_runmode to "".
lock Throttle to ThrottleIntent.
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
		if not sas {
			unlock steering.
			sas on.
			wait 0.1.
			set sasmode to "PROGRADE".
			}
		wait until MaxThrust > 0.
		set ThrottleIntent to ThrottleCap.
		if (LaunchGuidanceParameters["Stage Count"] >= LaunchGuidanceParameters["Skip Stages"]) { set runmode to "gravity turn". }
		}
	if runmode = "gravity turn" {
		wait until MaxThrust > 0.
		set ThrottleIntent to ThrottleGuidanceConstantTimeToApoapsis(LaunchTimeToApoapsis).
		if (Apoapsis >= OrbitAltitude) { set runmode to "maintain apoapsis". }
		}
	if (runmode = "maintain apoapsis") {
		if (Altitude > MinimumPeriapsis) { set runmode to "finished". }
		set apoapsis_error to max(0, OrbitAltitude - Apoapsis) / OrbitAltitude.
		set ThrottleIntent to ship:velocity:orbit:mag * apoapsis_error / maxthrust / mass.
		}
	}

set ThrottleIntent to 0.
unlock all.
set sasmode to "STABILITY".
print "Ascent completed.".
create_circularise_node().
ExecuteNextNode().

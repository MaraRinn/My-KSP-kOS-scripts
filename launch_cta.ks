Parameter LaunchGuidanceParameters is Lexicon("altitude", 0, "acceleration cap", 30, "draw vectors", false, "inclination", 0).

runoncepath("orbital_mechanics.ks").
runoncepath("lib/vessel_operations.ks").
runoncepath("lib/utility.ks").

lock LocalG to (body:mu / (body:radius + ship:altitude)^2).
set AccelerationCap to ParameterDefault(LaunchGuidanceParameters, "acceleration cap", 0). // m/s maximum acceleration
set DrawVectors to ParameterDefault(LaunchGuidanceParameters, "draw vectors", false).
if defined LaunchGuidanceSkipStages {
	set LaunchGuidanceParameters["Skip Stages"] to LaunchGuidanceSkipStages.
	}
else {
	set LaunchGuidanceParameters["Skip Stages"] to 0.
	}
set LaunchGuidanceParameters["Stage Count"] to 0.

set AtmosphereAltitude to BODY:ATM:HEIGHT.
set MinimumPeriapsis to max(AtmosphereAltitude, TerrainHeight()) + 100.
if (ParameterDefault(LaunchGuidanceParameters, "altitude", 0) < MinimumPeriapsis) {
	set LaunchGuidanceParameters["altitude"] to MinimumPeriapsis + 500.
	}
set OrbitAltitude to LaunchGuidanceParameters["altitude"] * 1.

if not(LaunchGuidanceParameters:HasKey("inclination")) {set LaunchGuidanceParameters["inclination"] to 0.}

// Vessel Specific Variables
set LaunchPitch to ParameterDefault(LaunchGuidanceParameters, "launch pitch", 80).
set LaunchTimeToApoapsis to ParameterDefault(LaunchGuidanceParameters, "time to apoapsis", 50).

function ThrottleCapMethod {
	if not (defined MaxThrust) or (MaxThrust = 0) { return 0. }
	if not (defined AccelerationCap) or (AccelerationCap = 0) { return 1. }
	return AccelerationCap * Mass / MaxThrust.
	}
set ThrottleCapDelegate to ThrottleCapMethod@.
lock ThrottleCap to ThrottleCapDelegate:Call.

function CappedAcceleration {
	if not (defined MaxThrust) or (MaxThrust = 0) { return 0. }
	set MaxAcceleration to MaxThrust / Mass.
	if not (defined AccelerationCap) or (AccelerationCap = 0) {
		return MaxAcceleration.
		}
	return AccelerationCap.
	}

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
lock Throttle to ThrottleIntent.

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
set PitchGuidancePID to pidloop(1,0,-1,-10,10).
set AoAIntent to 0.

function CalculatePitchIntent {
	parameter AngleOfAttack.

	if (AngleOfAttack > 5) { set AngleOfAttack to 5. }
	if (AngleOfAttack < -5) { set AngleOfAttack to -5. }
	set progradeVector to velocity:surface.
	set AngleFromZenith to VANG(up:foreVector, progradeVector).
	set pitchAngle to 90 - AngleFromZenith + AngleOfAttack.
	if pitchAngle > 85 { set pitchAngle to 85. }
	return pitchAngle.
	}

function LaunchAzimuth {
	parameter DesiredInclination.
	return ArcSin(Max(Min(Cos(DesiredInclination) / cos(ship:latitude), 1), -1)).
	}

function InclinationCorrectionVector {
	set DesiredVector to Heading(90,0):ForeVector.
	set ActualVector to ship:velocity:orbit.
	set CorrectionVector to DesiredVector.
	return CorrectionVector.
	}
//lock AzimuthIntent to VectorToCompassAngle(InclinationCorrectionVector()).
lock AzimuthIntent to 90.

function CalculateBurnTimeForCircularisation {
	set VelocityAtAP to VelocityAt(ship, eta:apoapsis):orbit:mag.
	set VelocityRequiredForOrbit to sqrt(body:mu / (apoapsis + body:radius)).
	set BurnTime to "--".
	if (CappedAcceleration()>0) {
		set BurnTime to (VelocityRequiredForOrbit - VelocityAtAP) / CappedAcceleration().
	}
	return BurnTime.
	}

function LaunchClampComparator {
	parameter Module.
	set IsAClamp to Module:Name:Contains("clamp").
	return IsAClamp.
	}

function ShipIsClamped {
	set ClampModules to ModulesMatching(LaunchClampComparator@).
	return (ClampModules:length > 0).
	}

function ActiveEngines {
	set ActiveEnginesList to List().
	list Engines in EngineList.
	for Engine in EngineList {
		if Engine:HasSuffix("Ignition") {
			ActiveEnginesList:Add(Engine).
			}
		}
	return ActiveEnginesList.
	}

function EnginesHaveFlamedOut {
	for Engine in ActiveEngines {
		if Engine:Flameout { return true. }
		}
	return false.
	}

function PrepareDisplayParameters {
	set parms to lexicon().
	set dvRequiredForOrbit to sqrt(body:mu / (apoapsis + body:radius)) - ship:Velocity:Orbit:Mag.
	parms:add("Target", round(OrbitAltitude,0)).
	parms:add("TTA", round(eta:apoapsis,2)).
	parms:add("Ap Alt", round(apoapsis,0)).
	parms:add("dv Circ", round(dvRequiredForOrbit,1)).
	parms:add("AoA", "NaN").
	parms:add("PI", "NaN").
	parms:add("YI", "NaN").
	parms:add("Runmode", runmode:PadLeft(20)).
	parms:add("Calc Time", 0).
	return parms.
	}

WHEN not (defined MaxThrust) or (MaxThrust = 0) THEN {
	stage.
	set LaunchGuidanceParameters["Stage Count"] to LaunchGuidanceParameters["Stage Count"] + 1.
	preserve.
	}

ConfigureCTTAThrottleGuidance(ThrottlePID, LaunchTimeToApoapsis).
ConfigureCTTAPitchGuidance(PitchGuidancePID, LaunchTimeToApoapsis).

print "Intended Apoapsis: " + OrbitAltitude.
print "Intended TTA:      " + LaunchTimeToApoapsis.
print "Minimum Periapsis: " + MinimumPeriapsis.

lock CrossTrackVector to VectorCrossProduct(body:position, ship:velocity:orbit). // aka Angular Momentum Vector h-hat
lock DownTrackVector to VectorCrossProduct(CrossTrackVector(), body:position).     // aka θ-hat
lock AngularVelocity to VectorDotProduct(ship:velocity:orbit, DownTrackVector():Normalized) / body:position:mag. // ω 
lock CentripedalForce to AngularVelocity^2 * body:position:mag.
lock VerticalAcceleration to (LocalG() - CentripedalForce()).

set PitchIntentVector to V(0,0,0).
set InclinationIntentVector to V(0,0,0).

if DrawVectors {
	global ProgradeArrow to VecDraw(V(0,0,0), {return velocity:surface.}, YELLOW, "Velocity", 1, true, 1).
	global OrbitProgradeArrow to VecDraw(V(0,0,0), {return velocity:orbit.}, RED, "OrbitV", 1, true, 1).
	global ForwardArrow to VecDraw(V(0,0,0), {return ship:facing:forevector:normalized * 50.}, CYAN, "", 1, true, 1).
	global VerticalAccelerationArrow to VecDraw(V(0,0,0), {return VerticalAcceleration() * body:position:normalized.}, WHITE, "", 1, true, 1).
	global ApoapsisVelocityArrow to VecDraw(V(0,0,0), {return VelocityAt(ship, time:seconds + eta:apoapsis):Orbit.}, RGB(204, 119,34), "Vap", 1, true, 1).
	}

set runmode to "prelaunch".
set SteeringIntent to up.
lock steering to SteeringIntent.
set oldApoapsis to apoapsis.
set oldApoapsisTime to time:seconds.
set dAdT to 0.
set adaptedTimeToApoapsis to LaunchTimeToApoapsis.
set old_runmode to "".
wait until MaxThrust > 0.
until runmode = "finished" {
	set startTime to TIME:seconds.
	set displayParameters to PrepareDisplayParameters().
	if not(old_runmode = runmode) {
		set old_runmode to runmode.
		}
	if EnginesHaveFlamedOut() {
		stage.
		wait until MaxThrust > 0.
		}
	if runmode = "prelaunch" {
		// if we're on the ground, start from scratch
		if (ship:velocity:surface:mag < 1) {
			set SteeringIntent to up.
			SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0. // Stop throttle resetting to 50%
			set runmode to "lift off".
			}
		else if (ship:velocity:surface:mag <= LocalG * 5) {set runmode to "lift off".}
		else {
			set runmode to "enter gravity turn".
			}
		}
	if runmode = "lift off" {
		if (ship:velocity:surface:mag > LocalG * 5) { set runmode to "clear launch area". }
		set SteeringIntent to up.
		set ThrottleIntent to ThrottleCap.
		if ShipIsClamped {
			wait 0.1.
			stage.
			}
		}
	if runmode = "clear launch area" {
		set SteeringIntent to Heading(AzimuthIntent, LaunchPitch).
		//if (vectorangle(ship:velocity:surface, SteeringIntent:ForeVector) <= 1) {
		//	set runmode to "enter gravity turn".
		//	}
		if (apoapsis > (altitude * 1.5) and eta:Apoapsis >= adaptedTimeToApoapsis) { set runmode to "gravity turn". }
		}
	if runmode = "enter gravity turn" {
		wait until MaxThrust > 0.
		set ThrottleIntent to ThrottleGuidanceConstantTimeToApoapsis(adaptedTimeToApoapsis).
		set SteeringIntent to Velocity:Surface:Direction.
		set TTAConverged to (ABS(adaptedTimeToApoapsis - eta:apoapsis) < 1).
		set StagesSkipped to (LaunchGuidanceParameters["Stage Count"] >= LaunchGuidanceParameters["Skip Stages"]).
		if StagesSkipped and TTAConverged { set runmode to "gravity turn". }
		}
	if runmode = "gravity turn" {
		wait until MaxThrust > 0.
		set ThrottleIntent to ThrottleGuidanceConstantTimeToApoapsis(adaptedTimeToApoapsis).
		set AoAIntent to PitchGuidanceConstantTimeToApoapsis(adaptedTimeToApoapsis).
		set PitchIntent to CalculatePitchIntent(AoAIntent).
		set AzimuthIntent to 90.
		set SteeringIntent to Heading(AzimuthIntent, PitchIntent).
		set displayParameters["PI"] to round(PitchIntent,1).
		set displayParameters["YI"] to round(AzimuthIntent,1).
		if (apoapsis > MinimumPeriapsis) {
			set runmode to "raise apoapsis".
			}
		}
	if runmode = "raise apoapsis" {
		wait until MaxThrust > 0.
		set OrbitRadius to OrbitAltitude + Body:Radius.
		set PositionRadius to altitude + Body:Radius.
		set newSemiMajorAxis to (OrbitRadius + PositionRadius) / 2.
		set newOrbitSpeed to velocityAtR(PositionRadius, newSemiMajorAxis, Orbit:Body:Mu).
		set deltaV to newOrbitSpeed - ship:velocity:orbit:mag.
		set SteeringIntent to ship:velocity:orbit:direction.
		set ThrottleIntent to min(deltaV/(2 * CappedAcceleration()), 1).
		if deltaV < 0.1 {
			set ThrottleIntent to 0.
			set runmode to "finished".
			}
		if apoapsis > OrbitAltitude {
			set ThrottleIntent to 0.
			set runmode to "finished".
			}
		}
	if (ship:velocity:surface:mag > 0) {
		set displayParameters["AoA"] to round(vectorangle(SteeringIntent:ForeVector, ship:velocity:surface),1).
		}
	set endTime to TIME:seconds.
	set calcTime to endTime - startTime.
	set displayParameters["Calc Time"] to round(calcTime, 3).
	set dApoapsis to apoapsis - oldApoapsis.
	set oldApoapsis to apoapsis.
	set dApoapsisTime to time:seconds - oldApoapsisTime.
	set oldApoapsisTime to time:seconds.
	set dAdT to dApoapsis/dApoapsisTime.
	set displayParameters["dAdT"] to round(dAdT, 0).
	set TimeToTargetApoapsis to (OrbitAltitude - altitude) / dAdT.
	set displayParameters["TTTA"] to round(TimeToTargetApoapsis, 0).
	set displayParameters["ATTA"] to round(adaptedTimeToApoapsis, 0).
	DisplayValues(displayParameters).
	}

set ThrottleIntent to 0.
print "Ascent completed.".
create_circularise_node().
wait 0.1.
unlock steering.
unlock throttle.
SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.
ExecuteNextNode().
ClearVecDraws().

unlock VerticalAcceleration.
unlock CentripedalForce.
unlock AngularVelocity.
unlock DownTrackVector.
unlock CrossTrackVector.

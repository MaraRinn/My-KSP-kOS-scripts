Parameter LaunchGuidanceParameters is Lexicon("altitude", 0, "acceleration cap", 30, "draw vectors", false, "inclination", 0).

runoncepath("orbital_mechanics.ks").
runoncepath("lib/vessel_operations.ks").
runoncepath("lib/utility.ks").

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
set MinimumPeriapsis to max(AtmosphereAltitude, TerrainHeight()) + 1.
if (ParameterDefault(LaunchGuidanceParameters, "altitude", 0) < MinimumPeriapsis) {
	set LaunchGuidanceParameters["altitude"] to MinimumPeriapsis + 500.
	}
set OrbitAltitude to LaunchGuidanceParameters["altitude"] * 1.

if not(LaunchGuidanceParameters:HasKey("inclination")) {set LaunchGuidanceParameters["inclination"] to 0.}

SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0. // Stop throttle resetting to 50%
lock LocalG to (body:mu / (body:radius + ship:altitude)^2).

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
set PitchGuidancePID to pidloop(1,0,-1,-30,30).
set AoAIntent to 0.

function CalculatePitchIntent {
	parameter AngleOfAttack.

	set progradeVector to velocity:surface.
	set AngleFromZenith to VANG(up:foreVector, progradeVector).
	set pitchAngle to 90 - AngleFromZenith + AngleOfAttack.
	return pitchAngle.
	}

function LaunchAzimuth {
	parameter DesiredInclination.
	return ArcSin(Max(Min(Cos(DesiredInclination) / cos(ship:latitude), 1), -1)).
	}

function DesiredOrbitalVector {
	set DesiredInclination to LaunchGuidanceParameters["inclination"].
	set DesiredAltitude to LaunchGuidanceParameters["altitude"].

	set RequiredAzimuth to LaunchAzimuth(DesiredInclination).
	set RequiredSpeed to sqrt(body:mu / (body:radius + DesiredAltitude)).
	set IntendedOrbitalVelocity to Heading(RequiredAzimuth,0):ForeVector:Normalized * RequiredSpeed.
	return IntendedOrbitalVelocity.
	}

function InclinationCorrectionVector {
	set DesiredVector to DesiredOrbitalVector.
	set ActualVector to ship:velocity:orbit.
	set CorrectionVector to DesiredVector - ActualVector.
	return CorrectionVector.
	}
lock AzimuthIntent to VectorToCompassAngle(InclinationCorrectionVector()).

function CalculateBurnTimeForCircularisation {
	set VelocityAtAP to VelocityAt(ship, eta:apoapsis):orbit:mag.
	set VelocityRequiredForOrbit to sqrt(body:mu / (apoapsis + body:radius)).
	set BurnTime to (VelocityRequiredForOrbit - VelocityAtAP) / CappedAcceleration().
	return BurnTime.
	}

// FIXME look for launch clamps and stage them too.
WHEN not (defined MaxThrust) or (MaxThrust = 0) THEN {
	stage.
	set LaunchGuidanceParameters["Stage Count"] to LaunchGuidanceParameters["Stage Count"] + 1.
	preserve.
	}

// Prepare for launch
set SteeringIntent to up.
lock steering to SteeringIntent.
ConfigureCTTAThrottleGuidance(ThrottlePID, LaunchTimeToApoapsis).
ConfigureCTTAPitchGuidance(PitchGuidancePID, LaunchTimeToApoapsis).

print "Intended Apoapsis: " + OrbitAltitude.
print "Intended TTA:      " + LaunchTimeToApoapsis.
print "Minimum Periapsis: " + MinimumPeriapsis.

lock CrossTrackVector to VectorCrossProduct(body:position, ship:velocity:orbit). // aka Angular Momentum Vector h-hat
lock DownTrackVector to VectorCrossProduct(CrossTrackVector, body:position).     // aka θ-hat
lock AngularVelocity to VectorDotProduct(ship:velocity:orbit, DownTrackVector:Normalized) / body:position:mag. // ω 
lock CentripedalForce to AngularVelocity^2 * body:position:mag.
lock VerticalAcceleration to (LocalG - CentripedalForce).
lock RemainingVelocityVector to DesiredOrbitalVector() - ship:velocity:orbit.

set PitchIntentVector to V(0,0,0).
set InclinationIntentVector to V(0,0,0).

if DrawVectors {
	global ProgradeArrow to VecDraw(V(0,0,0), {return velocity:surface.}, YELLOW, "Velocity", 1, true, 1).
	global ForwardArrow to VecDraw(V(0,0,0), {return ship:facing:forevector:normalized * 50.}, CYAN, "", 1, true, 1).
	global CrossTrackArrow to VecDraw(V(0,0,0), {return CrossTrackVector():Normalized * 30.}, BLUE, "XT", 0.5, true, 1).
	global DownTrackArrow to VecDraw(V(0,0,0), {return DownTrackVector():Normalized * 30.}, BLUE, "DT", 0.5, true, 1).
	global VerticalAccelerationArrow to VecDraw(V(0,0,0), {return VerticalAcceleration() * body:position:normalized.}, WHITE, "", 1, true, 1).
	global OrbitalIntentArrow to VecDraw(V(0,0,0), {return DesiredOrbitalVector().}, GREEN, "Orbit", 1, true, 1).
	global RemainingVelocityArrow to VecDraw(V(0,0,0), {return RemainingVelocityVector().}, BLUE, "∆V", 1, true, 1).
	}

set runmode to "lift off".
set old_runmode to "".
wait until MaxThrust > 0.
until runmode = "finished" {
	if not(old_runmode = runmode) {
		print "Runmode: " + runmode.
		set old_runmode to runmode.
		}
	if runmode = "lift off" {
		if (ship:velocity:surface:mag > LocalG * 10) { set runmode to "clear launch area". }
		set SteeringIntent to up.
		set ThrottleIntent to ThrottleCap.
		}
	if runmode = "clear launch area" {
		if (ship:velocity:surface:mag > LocalG * 20) { set runmode to "enter gravity turn". }
		set SteeringIntent to Heading(AzimuthIntent, LaunchPitch).
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
		set PitchIntent to CalculatePitchIntent(AoAIntent).
		set SteeringIntent to Heading(AzimuthIntent, PitchIntent).
		print "PI: " + round(PitchIntent,1) + "      " at (0, 20).
		print "YI: " + round(AzimuthIntent,1) + "     " at (0,21).
		if (VANG(ship:Facing:ForeVector, up:forevector) > 85) or (apoapsis >= OrbitAltitude) { set runmode to "maintain apoapsis". }
		}
	if (runmode = "maintain apoapsis") {
		wait until MaxThrust > 0.
		if (Altitude > MinimumPeriapsis) { set runmode to "finished". }
		set apoapsis_error to max(0, OrbitAltitude - Apoapsis) / OrbitAltitude.
		set ThrottleIntent to ship:velocity:orbit:mag * apoapsis_error / maxthrust * mass.
		set SteeringIntent to ship:velocity:orbit.
		set BurnTime to CalculateBurnTimeForCircularisation.
		if BurnTime > eta:apoapsis { set runmode to "finished". }
		}
	}

set ThrottleIntent to 0.
print "Ascent completed.".
create_circularise_node().
unlock steering.
unlock throttle.
ExecuteNextNode().
ClearVecDraws().
unlock all.

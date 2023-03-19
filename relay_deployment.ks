parameter numberOfRelays is 3.
parameter periapsisLeadTime is 120.

// Run this script on the deployer vessel.
// All the satellites should be connected directly to the deployer via decouplers.
// Exactly one component on each relay satellite should be tagged "Relay N" (where N is a single digit)
// There can also be one (or no) satellite tagged "Survey"
//
// The deployer will attempt to set up a resonant orbit, then deploy one satellite per orbit.
// For most bodies this resonant orbit will be a stationary orbit for the deployed satellites
//    and a (N-1)/N resonant orbit for the deployer. Where this can't happen, the script will
//    try the options of half or a third of the stationary orbit period.
// The relay satellites will adjust their orbit to the appropriate period (this may result in wonky orbits)
// The survey satellite will attempt to insert itself into the suitable survey orbit for the body it's orbiting.

runoncepath("lib/orbital_mechanics.ks").
runoncepath("lib/vessel_operations.ks").
runoncepath("lib/utility.ks").

set AtmosphereAltitude to BODY:ATM:HEIGHT.
set MinimumPeriapsis to max(AtmosphereAltitude, TerrainHeight()) + 100.
set intendedPeriod to 0.
set desiredDeployerApoapsis to 0.

function PrepareOrbit {
	parameter desiredRelayPeriod is orbit:body:rotationPeriod.

	set desiredRelaySMA to SemiMajorAxisFromPeriod(desiredRelayPeriod).
	set desiredRelayAltitude to desiredRelaySMA - body:radius.
	set desiredDeployerPeriod to desiredRelayPeriod * (numberOfRelays + 1)/numberOfRelays.
	set desiredDeployerSMA to SemiMajorAxisFromPeriod(desiredDeployerPeriod).
	set desiredDeployerApoapsis to 2 * desiredDeployerSMA - desiredRelaySMA - body:radius.
	set desiredDeployerPeriapsis to desiredRelayAltitude.

	clearscreen.
	print "Deployment Parameters:".
	print "Relay Altitude: " + desiredRelayAltitude.
	print "Deployer Ap:    " + desiredDeployerApoapsis.
	print "Deployer P:     " + TimeString(desiredDeployerPeriod).
	}

function CheckOrbitalParameters {
	PrepareOrbit.
	if desiredDeployerApoapsis > (body:soiRadius - body:radius) {
		print "(trying again with half stationary period)".
		set intendedPeriod to body:rotationPeriod / 2.
		PrepareOrbit(intendedPeriod).
		}
	if desiredDeployerApoapsis > (body:soiRadius - body:radius) {
		print "(trying again with one third stationary period)".
		set intendedPeriod to orbit:body:rotationPeriod / 3.
		PrepareOrbit(intendedPeriod).
		}

	if abs(orbit:inclination) >= 0.7 {
		print "Adjusting inclination.".
		AlterInclination(0).
		}
	if not HasNode and (orbit:periapsis < MinimumPeriapsis) {
		print "Raising periapsis to minimum safe altitude".
		AlterPeriapsis(MinimumPeriapsis + 100).
		}
	if not HasNode and not WithinError(orbit:apoapsis, desiredDeployerApoapsis) {
		print "Adjusting apoapsis from " + round(orbit:apoapsis) + " to " + round(desiredDeployerApoapsis).
		AlterApoapsis(desiredDeployerApoapsis).
		}
	if not HasNode and not withinError(orbit:periapsis, desiredDeployerPeriapsis) {
		print "Adjusting periapsis from " + round(orbit:periapsis) + " to " + round(desiredDeployerPeriapsis).
		AlterPeriapsis(desiredDeployerPeriapsis).
		}
	}

function ReadyForDeployment {
	set isOrbitCorrect to 0.
	if (desiredDeployerPeriod > 0) {
		if (abs(desiredDeployerApoapsis - ship:apoapsis) < 1000) {
			if (abs(desiredDeployerPeriapsis - ship:periapsis) < 1000) {
				if (abs(desiredDeployerPeriod - ship:orbit:period) < 120) {
					set isOrbitCorrect to 1.
					}
				}
			}
		}
	else {
		print "No intended period calculated.".
		}
	return isOrbitCorrect.
}

if hasNode {
	print "Waiting for manoeuvre.".
	sas off.
	WaitForNode().
	reboot.
	}
else if HasAlarm() {
	WaitForAlarm().
	}
CheckOrbitalParameters().

// At this point the deployer should be on the appropriate orbit.
if ReadyForDeployment {
	set relayCandidates to ship:partstaggedpattern("Relay \d").
	set surveyCandidates to ship:partstaggedpattern("Survey").
	set intendedPeriod to body:rotationPeriod.
	print "Orbit looks good.".
	
	if (relayCandidates:length > 0 ) {
		if eta:periapsis <= periapsisLeadTime {
			print "Launching relay.".
			sas on.
			wait 1.
			set sasmode to "RETROGRADE".
			wait until ship:angularvel:mag < 0.2.
			set deployPoint to time:seconds + orbit:period + eta:periapsis - periapsisLeadTime. // next deployment is next orbit
			run launch_relay.
			}
		else {
			set deployPoint to time:seconds + eta:periapsis - periapsisLeadTime.
			}
		if Addons:Available("KAC") {
			// Use Kerbal Alarm Clock
			set deployAlarm  to addAlarm("Raw", deployPoint, "Deploy Satellite", "The deployer is approaching periapsis, time to deploy the next satellite.").
			}
		else {
			set destinationNode to Node(deployPoint, 0, 0, 0).
			add destinationNode.
			print "Waiting for next deployment opportunity.".
			}
		}
	else if (surveyCandidates:length > 0) {
		print "Launching survey.".
		run launch_relay.
		}
	else {
		print "Deployment complete.".
		set core:bootfilename to "".
		}
	}
wait 5.
reboot.

parameter numberOfRelays is 3.
parameter periapsisLeadTime is 120.

runoncepath("orbital_mechanics.ks").
runoncepath("lib/vessel_operations.ks").

function PrepareOrbit {
	parameter desiredRelayPeriod is orbit:body:rotationPeriod.

	set desiredRelaySMA to SemiMajorAxisFromPeriod(desiredRelayPeriod).
	set desiredRelayAltitude to desiredRelaySMA - body:radius.
	set desiredDeployerSMA to SemiMajorAxisFromPeriod(desiredRelayPeriod * (numberOfRelays + 1)/numberOfRelays).
	set desiredDeployerApoapsis to 2 * desiredDeployerSMA - desiredRelaySMA - body:radius.
	set desiredDeployerPeriapsis to desiredRelayAltitude.

	clearscreen.
	print "Deployment Parameters:".
	print "Relay Altitude: " + desiredRelayAltitude.
	print "Deployer Ap:    " + desiredDeployerApoapsis.
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
	else if not WithinError(orbit:apoapsis, desiredDeployerApoapsis) {
		print "Adjusting apoapsis from " + round(orbit:apoapsis) + " to " + round(desiredDeployerApoapsis).
		AlterApoapsis(desiredDeployerApoapsis).
		}

	else if not withinError(orbit:periapsis, desiredDeployerPeriapsis) {
		print "Adjusting periapsis from " + round(orbit:periapsis) + " to " + round(desiredDeployerPeriapsis).
		AlterPeriapsis(desiredDeployerPeriapsis).
		}
	}

function AdjustAttitudeForDeployment {
	sas on.
	wait 1.
	set sasmode to "RETROGRADE".
	wait until VectorAngle(ship:velocity:orbit, ship:facing:vector) > 135.
	wait until ship:angularvel:mag < 0.2.
	}

if hasNode {
	print "Waiting for manoeuvre.".
	sas off.
	WaitForNode().
	}
else if HasAlarm() {
	WaitForAlarm().
	}
else {
	CheckOrbitalParameters().
	}

set relayCandidates to ship:partstaggedpattern("Relay \d").
set surveyCandidates to ship:partstaggedpattern("Survey").
set intendedPeriod to body:rotationPeriod.

// At this point the deployer is on the appropriate orbit.
if not HasNode {
	print "Orbit looks good.".
	
	if (relayCandidates:length > 0 ) {
		if eta:periapsis <= periapsisLeadTime {
			print "Launching relay.".
			AdjustAttitudeForDeployment().
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
reboot.

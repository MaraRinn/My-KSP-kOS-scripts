parameter numberOfRelays is 3.

runoncepath("orbital_mechanics.ks").

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

sas on.
wait 1.

if hasNode {
	print "Executing manoeuvre.".
	if sasmode = "MANEUVER" { sas off. }
	run execute_next_node.
	}

set relayCandidates to ship:partstaggedpattern("Relay \d").
set surveyCandidates to ship:partstaggedpattern("Survey").

PrepareOrbit.
if desiredDeployerApoapsis > (body:soiRadius - body:radius) {
	print "(trying again with half stationary period)".
	PrepareOrbit(orbit:body:rotationPeriod / 2).
	}
if desiredDeployerApoapsis > (body:soiRadius - body:radius) {
	print "(trying again with one third stationary period)".
	PrepareOrbit(orbit:body:rotationPeriod / 3).
	}

if not withinError(orbit:apoapsis, desiredDeployerApoapsis) and not withinError(orbit:apoapsis, desiredDeployerPeriapsis) {
	print "Adjusting apoapsis from " + round(orbit:apoapsis) + " to " + round(desiredDeployerApoapsis).
	AlterApoapsis(desiredDeployerApoapsis).
	if NextNode:deltav:mag > 0.1 {
		set sasmode to "MANEUVER".
		}
	else {
		remove NextNode.
		}
	}

if not HasNode and withinError(orbit:apoapsis, desiredDeployerPeriapsis) {
	print "Fiddling with the orbit a bit.".
	AlterPeriapsis(desiredDeployerApoapsis).
	if NextNode:deltav:mag > 0.1 {
		set sasmode to "MANEUVER".
		}
	else {
		remove NextNode.
		}
	}

if not HasNode and not withinError(orbit:periapsis, desiredDeployerPeriapsis) {
	print "Adjusting periapsis from " + round(orbit:periapsis) + " to " + round(desiredDeployerPeriapsis).
	AlterPeriapsis(desiredDeployerPeriapsis).
	if NextNode:deltav:mag > 0.1 {
		set sasmode to "MANEUVER".
		}
	else {
		remove NextNode.
		}
	}

// At this point the deployer is on the appropriate orbit.
if not HasNode {
	print "Orbit looks good.".
	set sasmode to "RETROGRADE".
	set deployPoint to eta:periapsis - 300.
	if deployPoint < 0 {
		set deployPoint to deployPoint + orbit:period.
		}
	if (relayCandidates:length > 0 ) {
		if eta:periapsis < 300 {
			print "Launching relay.".
			run launch_relay.
			}
		set destinationNode to Node(time:seconds + deployPoint, 0, 0, 0).
		add destinationNode.
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

parameter numberOfRelays is 4.

runoncepath("orbital_mechanics.ks").

sas on.
wait 1.

if hasNode {
	print "Executing manoeuvre.".
	run execute_next_node.
	}

set relayCandidates to ship:partstaggedpattern("Relay \d").
set surveyCandidates to ship:partstaggedpattern("Survey").

set desiredRelayPeriod to body:rotationperiod.
lock desiredRelaySMA to SemiMajorAxisFromPeriod(desiredRelayPeriod).
if desiredRelaySMA > body:SOIradius {
	set desiredRelayPeriod to body:rotationperiod / 2.
	}
set desiredRelayAltitude to desiredRelaySMA - body:radius.
set desiredDeployerSMA to SemiMajorAxisFromPeriod(desiredRelayPeriod * (numberOfRelays + 1)/numberOfRelays).
set desiredDeployerApoapsis to 2 * desiredDeployerSMA - desiredRelaySMA - body:radius.
set desiredDeployerPeriapsis to desiredRelaySMA - body:radius.

if not withinError(orbit:apoapsis, desiredDeployerApoapsis) and not withinError(orbit:apoapsis, desiredDeployerPeriapsis) {
	print "Adjusting apoapsis from " + round(orbit:apoapsis) + " to " + round(desiredDeployerApoapsis).
	AlterApoapsis(desiredDeployerApoapsis).
	set sasmode to "MANEUVER".
	}
else if withinError(orbit:apoapsis, desiredDeployerApoapsis) and not withinError(orbit:periapsis, desiredDeployerPeriapsis) {
	print "Adjusting periapsis from " + round(orbit:periapsis) + " to " + round(desiredDeployerPeriapsis).
	AlterPeriapsis(desiredDeployerPeriapsis).
	set sasmode to "MANEUVER".
	}
else if withinError(orbit:apoapsis, desiredDeployerPeriapsis) {
	print "Fiddling with the orbit a bit.".
	AlterPeriapsis(desiredDeployerApoapsis).
	set sasmode to "MANEUVER".
	}

// At this point the deployer is on the appropriate orbit.
else {
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
			print " … waiting till we pass periapsis.".
			wait until eta:periapsis > 300.
			}
		else {
			set destinationNode to Node(time:seconds + deployPoint, 0, 0, 0).
			add destinationNode.
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

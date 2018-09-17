runoncepath("orbital_mechanics").

set queue to ship:messages.
set Ship:Control:PilotMainThrottle to 0.
set deploymentComplete to false.

on Abort {
	set deploymentComplete to true.
	}

function desiredVelocity {
	parameter myOrbit is orbit.

	set intendedPeriod to myOrbit:body:rotationPeriod.
	set halfPeriod to intendedPeriod / 2.
	set thirdPeriod to intendedPeriod / 3.
	set currentPeriod to PeriodFromSemiMajorAxis(periapsis + body:radius).
	print "Current:  " + round(currentPeriod).
	print "Intended: " + round(intendedPeriod).
	print "Half:     " + round(halfPeriod).
	print "Third:    " + round(thirdPeriod).
	if round(currentPeriod / halfPeriod, 1) = 1 {
		set intendedPeriod to halfPeriod.
		}
	else if round(currentPeriod / thirdPeriod, 1) = 1 {
		set intendedPeriod to thirdPeriod.
		}
	
	set desiredRadius to SemiMajorAxisFromPeriod(intendedPeriod).

	set intendedVelocity to VelocityAtR(altitude + orbit:body:radius, desiredRadius, orbit:body:mu).
	return intendedVelocity.
	}

function AdjustOrbit {
	sas on.
	wait 0.1.
	
	set intendedVelocity to desiredVelocity.
	print "Intended: " + round(intendedVelocity,3) + "m/s Actual: " + round(velocity:orbit:mag,3) + "m/s".
	set velocityError to intendedVelocity - velocity:orbit:mag.

	if (velocityError > 0) { set sasmode to "PROGRADE". }
	if (velocityError < 0) { set sasmode to "RETROGRADE". }
	if (abs(velocityError) < 0.001) {
		set deploymentComplete to true.
		return.
		}

	set velocityError to abs(velocityError).
	print "Adjusting velocity by about " + round(velocityError,3) + "m/s".
	set maxAcceleration to maxThrust / mass.
	if velocityError > maxAcceleration {
		set intendedAcceleration to maxAcceleration.
		set burnDuration to velocityError / intendedAcceleration.
		set intendedThrottle to 1.
		}
	else {
		set intendedAcceleration to maxAcceleration / 10.
		set burnDuration to velocityError / intendedAcceleration.
		set intendedThrottle to 0.1.
		}
	print "Burn time: " + burnDuration + " at " + intendedThrottle + " throttle.".
	wait 1.
	wait until ship:angularvel:mag < 0.001.
	set throttle to intendedThrottle.
	wait burnDuration.
	set throttle to 0.
	sas off.
	}

function Deploy {
	parameter message.
	set engineFound to false.
	set part to core:part.
	set ship:name to body + " " + core:tag.

	until engineFound {
		set part to part:parent.
		for module in part:modules {
			if module:matchespattern("engine"){
				set enginePart to part.
				set engineModule to part:GetModule(module).
				set engineFound to true.
				}
			}
		}
	engineModule:DoAction("activate engine", true).
	panels on.

	AdjustOrbit.
	AdjustOrbit.
	
	set myConnection to message:sender:connection.
	myConnection:SendMessage("deployed").
	set kUniverse:ActiveVessel to message:sender.
	}

function HandleMessage {
	parameter message.

	if hasNode {
		set lastNode to AllNodes[AllNodes:Length - 1].
		set lastOrbit to lastNode:orbit.
		set noEarlierThan to lastNode:eta + time:seconds.
		}
	else {
		set lastOrbit to orbit.
		set noEarlierThan to time:seconds.
		}

	if thisMessage:content[0] = "reboot" {
		reboot.
		}
	if thisMessage:content[0] = "deploy" {
		set kUniverse:ActiveVessel to ship.
		Deploy(thisMessage).
		}
	if thisMessage:content[0] = "apoapsis" {
		set kUniverse:ActiveVessel to ship.
		set desiredApoapsis to thisMessage:content[1].
		print "Setting apoapsis to " + desiredApoapsis.
		AlterApoapsis(desiredApoapsis, lastOrbit, noEarlierThan).
		}
	if thisMessage:content[0] = "periapsis" {
		set kUniverse:ActiveVessel to ship.
		set desiredPeriapsis to thisMessage:content[1].
		print "Setting periapsis to " + desiredPeriapsis.
		AlterPeriapsis(desiredPeriapsis, lastOrbit, noEarlierThan).
		}
	if thisMessage:content[0] = "inclination" {
		set kUniverse:ActiveVessel to ship.
		set desiredInclination to thisMessage:content[1].
		print "Setting inclination to " + desiredInclination.
		AlterInclination(desiredInclination). // FIXME - AlterInclination is fragile on orbits
		}
	if thisMessage:content[0] = "goodbye" {
		set deploymentComplete to true.
		}
	}

until deploymentComplete {
	wait 10.
	print "Hello world.".
	if not queue:empty {
		set thisMessage to queue:pop().
		print "Ooh! A message! It says '" + thisMessage:content[0] + "'".
		HandleMessage(thisMessage).
		}
	}

set core:bootfilename to "".

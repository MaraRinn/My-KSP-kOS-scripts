runoncepath("orbital_mechanics").
set throttleSetting to 0.
lock throttle to throttleSetting.
lock SunwardVector to sun:position.

function desiredVelocity {
	parameter myOrbit is orbit.
	parameter myAltitude is altitude.

	set intendedPeriod to myOrbit:body:rotationPeriod.
	set currentPeriod to myOrbit:Period.
	set intendedRatio to round(currentperiod / intendedPeriod, 1).
	set halfPeriod to intendedPeriod / 2.
	set halfRatio to round(currentperiod / halfPeriod, 1).
	set thirdPeriod to intendedPeriod / 3.
	set thirdRatio to round(currentperiod / thirdPeriod, 1).
	print "Current period: " + round(currentPeriod).
	print "Intended:       " + round(intendedPeriod) + " (" + intendedRatio + ")".
	print "Half period:    " + round(halfperiod) + " (" + halfRatio + ")".
	print "Third period:   " + round(thirdPeriod) + " (" + thirdRatio + ")".
	if intendedRatio > 0.9 {
		// do nothing
		}
	else if halfRatio > 0.9 {
		set intendedPeriod to halfPeriod.
		}
	else if thirdRatio >= 0.9 {
		set intendedPeriod to thirdPeriod.
		}
	print "Using:          " + round(intendedPeriod).
	
	set desiredSMA to SemiMajorAxisFromPeriod(intendedPeriod).

	set intendedVelocity to VelocityAtR(myAltitude + myOrbit:body:radius, desiredSMA, myOrbit:body:mu).
	return intendedVelocity.
	}

function AdjustRelayOrbit {
	sas on.
	wait 1.
	
	set intendedVelocityVector to desiredVelocity * prograde:vector:normalized.
	print "Intended: " + round(intendedVelocityVector:mag,3) + "m/s Actual: " + round(velocity:orbit:mag,3) + "m/s".
	set velocityErrorVector to intendedVelocityVector - velocity:orbit.
	set velocityError to velocityErrorVector * prograde:vector.

	if (abs(velocityError) < 0.005) {
		set deploymentComplete to true.
		return true.
		}
	if velocityError > 0 { set sasmode to "PROGRADE". }
	if velocityError < 0 { set sasmode to "RETROGRADE". }
	wait 0.1.

	set deltav to abs(velocityError).
	print "Adjusting velocity by about " + round(velocityError,3) + "m/s".
	set maxAcceleration to maxThrust / mass.
	if deltav > maxAcceleration {
		set intendedAcceleration to maxAcceleration.
		set burnDuration to deltav / intendedAcceleration.
		set intendedThrottle to 1.
		}
	else {
		set intendedAcceleration to maxAcceleration / 10.
		set burnDuration to deltav / intendedAcceleration.
		set intendedThrottle to 0.1.
		}
	print "Burn time: " + burnDuration + " at " + intendedThrottle + " throttle.".
	wait until ship:angularvel:mag < 0.001.
	set throttleSetting to intendedThrottle.
	wait burnDuration.
	set throttleSetting to 0.
	return false.
	}

function ActivateEngine {
	set part to core:part.
	set engineFound to false.
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
	}

function Deploy {
	set part to core:part.
	set kUniverse:ActiveVessel to ship.
	set kUniverse:timeWarp:Warp to 0.
	set ship:name to body:name + " " + core:tag.
	panels on.
	}

function HasDecoupler {
	set part to core:part.
	set decouplerFound to false.
	until decouplerFound {
		set part to part:parent.
		for module in part:modules {
			if module:matchespattern("decouple") {
				set decouplerFound to true.
				}
			}
		if not part:HasParent { break. }
		}
	return decouplerFound.
	}

function FarEnoughAway {
	list targets in thingsInSpace.
	set enoughRoomToDeploy to true.
	for thing in thingsInSpace {
		if thing:distance < 20 {
			set enoughRoomToDeploy to false.
			}
		}
	return enoughRoomToDeploy.
	}

function ClosestVessel {
	list targets in thingsInSpace.
	set closest to thingsInSpace[0].
	for thing in thingsInSpace {
		if thing:distance < closest:distance {
			set closest to thing.
			}
		}
	return closest.
	}

set Ship:Control:PilotMainThrottle to 0.
set ParentVessel to ClosestVessel.

if HasDecoupler {
	print "Waiting for separation.".
	wait until not HasDecoupler.
	reboot. // FIXME kOS processors get confused over separation events
	}

if not FarEnoughAway {
	print "Waiting for safe distance.".
	ActivateEngine().
	set throttleSetting to 0.1.
	wait 5.
	set throttleSetting to 0.
	until FarEnoughAway {
		wait 10.
		}
	if eta:periapsis < 300 {
		print "Waiting until periapsis.".
		wait until eta:periapsis < 10.
		}
	reboot.
	}

print "Deploying.".
Deploy.

until AdjustRelayOrbit {
	print "Further adjustment may be required.".
	wait 1.
	}

set core:bootfilename to "boot/simpleboot.ks".
set kUniverse:ActiveVessel to ParentVessel.
reboot.

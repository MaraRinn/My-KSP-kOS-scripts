runoncepath("orbital_mechanics").
runoncepath("lib/vessel_operations").
set Ship:Control:PilotMainThrottle to 0.
set throttleSetting to 0.
lock throttle to throttleSetting.
lock sunwardVector to sun:position.

list resources in resList.
for res in resList {
	if res:name = "ElectricCharge" {
		set electric to res.
		}
	}

function HasDecoupler {
	set part to core:part.
	set decouplerFound to false.
	until decouplerFound {
		set part to part:parent.
		for module in part:modules {
			if module:matchespattern("decouple"){
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
	set kUniverse:ActiveVessel to ship.
	set kUniverse:timeWarp:Warp to 0.
	panels on.
	set ship:name to body:name + " " + core:tag.

	for part in ship:parts {
		for moduleName in part:modules {
			set module to part:getModule(moduleName).
			if module:HasAction("deploy scanner") {
				module:DoAction("deploy scanner", true).
				}
			if module:HasAction("extend antenna") {
				module:DoAction("extend antenna", true).
				}
			}
		}
	}

function OrbitGood {
	set surveyAltitude to max( max(body:radius / 10, 25000), BODY:ATM:HEIGHT) + 1000.
	print "Survey altitude: " + surveyAltitude.
	print "Inclination:     " + round(orbit:inclination).
	print "Periapsis:       " + round(orbit:periapsis).
	print "Apoapsis:        " + round(orbit:apoapsis).
	set maxAcceleration to maxThrust / mass.
	set dvLimit to maxAcceleration * 120.
	if round(orbit:inclination) <> 90 {
		print "Setting polar orbit.".
		AlterPlane(90 - orbit:inclination, time:seconds + eta:apoapsis).
		return false.
		}

	if not WithinError(orbit:periapsis, surveyAltitude, 0.01) {
		print "Adjusting periapsis to " + round(surveyAltitude) + "m".
		set peNode to AlterPeriapsis(surveyAltitude, orbit, time:seconds, dvLimit).
		if peNode:deltav:mag < 0.1 {
			remove NextNode.
			}
		else {
			return false.
			}
		}
	if not WithinError(orbit:apoapsis, surveyAltitude, 0.01) {
		print "Adjusting apoapsis to " + round(surveyAltitude) + "m".
		set apNode to AlterApoapsis(surveyAltitude, orbit, time:seconds, dvLimit).
		if apNode:deltav:mag < 0.1 {
			remove NextNode.
			}
		else {
			return false.
			}
		}
	return true.
	}

function PerformSurvey {
	// Don't try performing a survey in the shade
	if not CanSurvey("Communotron 16") { return false. }

	print "Performing survey.".
	set surveyEventName to "Perform Orbital Survey".
	set scanners to ship:PartsDubbedPattern("SurveyScanner").
	if scanners:Length = 0 {
		print " … no scanner found.".
		return false.
		}
	set scanner to scanners[0].
	set surveyModule to scanner:GetModule("ModuleOrbitalSurveyor").
	for event in surveyModule:AllEvents {
		if event:MatchesPattern(surveyEventName) {
			sas on.
			wait 1.
			set sasmode to "RADIALIN".
			surveyModule:DoEvent(surveyEventName).
			return true.
			}
		}
	print " … oops.".
	return false.
	}

if HasNode {
	print "Establishing Orbit.".
	sas off.
	WaitForNode().
	sas on.
	}
else if HasDecoupler {
	print "Waiting for separation.".
	wait until not HasDecoupler.
	reboot. // FIXME kOS processors get confused over separation events
	}
else if not FarEnoughAway {
	print "Waiting for safe distance.".
	ActivateEngine().
	set throttleSetting to 0.1.
	wait 5.
	set throttleSetting to 0.
	until FarEnoughAway {
		wait 10.
		}
	Deploy().
	}
else if not OrbitGood {
	print "Orbital correction required.".
	}
else if PerformSurvey {
	print "Survey completed.".
	set core:bootfilename to "boot/simpleboot.ks".
	}
reboot.

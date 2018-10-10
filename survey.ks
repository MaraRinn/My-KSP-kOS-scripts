runoncepath("orbital_mechanics").

set Ship:Control:PilotMainThrottle to 0.
set deploymentComplete to false.

list resources in resList.
for res in resList {
	if res:name = "ElectricCharge" {
		set electric to res.
		}
	}

on Abort {
	set deploymentComplete to true.
	}

function Deploy {
	panels on.
	set ship:name to body:name + " " + core:tag.

	set engineFound to false.
	set part to core:part.
	until engineFound {
		set part to part:parent.
		for module in part:modules {
			if module:matchespattern("engine"){
				set enginePart to part.
				set engineModule to part:GetModule(module).
				engineModule:DoAction("activate engine", true).
				set engineFound to true.
				}
			}
		}
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

function AdjustOrbit {
	set surveyAltitude to max( max(body:radius / 10, 25000), BODY:ATM:HEIGHT) + 1000.
	set dirty to false.
	set maxAcceleration to maxThrust / mass.
	set dvLimit to maxAcceleration * 120.
	if round(orbit:inclination) <> 90 {
		print "Setting polar orbit.".
		AlterPlane(90 - orbit:inclination, time:seconds + eta:apoapsis).
		return true.
		}

	if not withinError(orbit:periapsis, surveyAltitude, 0.01) {
		print "Adjusting periapsis to " + round(surveyAltitude) + "m".
		set peNode to AlterPeriapsis(surveyAltitude, orbit, time:seconds, dvLimit).
		if peNode:deltav:mag < 0.1 {
			remove NextNode.
			}
		else {
			return true.
			}
		}
	if not withinError(orbit:apoapsis, surveyAltitude, 0.01) {
		print "Adjusting apoapsis to " + round(surveyAltitude) + "m".
		set apNode to AlterApoapsis(surveyAltitude, orbit, time:seconds, dvLimit).
		if apNode:deltav:mag < 0.1 {
			remove NextNode.
			set adjustAP to false.
			}
		else {
			return true.
			}
		}
	return false.
	}

function PerformSurvey {
	// Don't try performing a survey in the shade
	if electric:amount < 500 { return false. }

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

function Detached {
	set part to core:part.
	set decouplerFound to false.
	until decouplerFound {
		set part to part:parent.
		for module in part:modules {
			if module:matchespattern("decouple"){
				set decouplerPart to part.
				set decouplerModule to part:GetModule(module).
				print "Decoupler found".
				set decouplerFound to true.
				}
			}
		if not part:HasParent { break. }
		}
	return not decouplerFound.
	}

function FarEnoughAway {
	list targets in thingsInSpace.
	set enoughRoomToDeploy to true.
	for thing in thingsInSpace {
		if thing:distance < 20 {
			print "personal space please!".
			set enoughRoomToDeploy to false.
			}
		}
	return enoughRoomToDeploy.
	}

print "Initial Boot.".
until deploymentComplete {
	wait 60.
	print "Hello world.".
	if Detached and FarEnoughAway {
		Deploy.
		set deploymentComplete to true.
		}
	}

set deploymentComplete to false.

print "Establishing Orbit.".
until deploymentComplete {
	if hasNode {
		sas off.
		run "execute_next_node".
		sas on.
		}
	else if not AdjustOrbit {
		set deploymentComplete to PerformSurvey.
		}
	else {
		wait 60.
		}
	}

print "Survey completed.".
set core:bootfilename to "".

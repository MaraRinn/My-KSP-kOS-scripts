runoncepath("orbital_mechanics").

set queue to ship:messages.
set Ship:Control:PilotMainThrottle to 0.
set deploymentComplete to false.

on Abort {
	set deploymentComplete to true.
	}

function Deploy {
	parameter message.

	panels on.

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
	set ship:name to core:tag.
	
	set myConnection to message:sender:connection.
	myConnection:SendMessage("deployed").
	set kUniverse:ActiveVessel to message:sender.
	}

function AdjustOrbit {
	set surveyAltitude to max( max(body:radius / 10, 25000), BODY:ATM:HEIGHT) + 1000.
	set dirty to false.
	if round(orbit:inclination) <> 90 {
		print "Setting polar orbit.".
		AlterInclination(90).
		set dirty to true.
		}
	else if not withinError(orbit:periapsis, surveyAltitude, 0.01) {
		print "Adjusting periapsis to " + round(surveyAltitude) + "m".
		AlterPeriapsis(surveyAltitude, orbit, time:seconds).
		set dirty to true.
		}
	else if not withinError(orbit:apoapsis, surveyAltitude, 0.01) {
		print "Adjusting apoapsis to " + round(surveyAltitude) + "m".
		AlterApoapsis(surveyAltitude, orbit, time:seconds).
		set dirty to true.
		}
	return dirty.
	}

function PerformSurvey {
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
		deploy(thisMessage).
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

print "Initial Boot.".
until deploymentComplete {
	wait 10.
	print "Hello world.".
	if not queue:empty {
		set thisMessage to queue:pop().
		print "Ooh! A message! It says '" + thisMessage:content[0] + "'".
		HandleMessage(thisMessage).
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

runoncepath("orbital_mechanics").

sas on.
set Ship:Control:PilotMainThrottle to 0.
wait 1.

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

function desiredAltitude {
	parameter purpose is "Relay".
	
	if purpose = "Relay" {
		set altitudeIntent to SemiMajorAxisFromPeriod(orbit:body:rotationperiod).
		if altitudeIntent > orbit:body:soiradius {
			set altitudeIntent to SemiMajorAxisFromPeriod(orbit:body:rotationperiod/2).
			}
		}
	else if purpose = "Survey" {
		// https://wiki.kerbalspaceprogram.com/wiki/M700_Survey_Scanner
		set altitudeIntent to max(max(orbit:body:radius / 10, 25), orbit:body:atm:height).
		}
	return altitudeIntent.
	}

function NearestVessel {
	list targets in myTargets.
	set closest to myTargets[0].
	for candidate in myTargets {
		if candidate:distance < closest:distance {
			set closest to candidate.
			}
		}
	return closest.
	}

function deploy {
	set engineFound to false.
	set part to core:part.
	set kUniverse:ActiveVessel to ship.

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

	if core:tag:contains("Relay") {
		set lastNode to create_circularise_node(false).
		set lastNode to AlterPeriapsis(desiredAltitude("Relay"), lastNode:orbit, time:seconds + lastNode:ETA).
		set lastNode to AlterApoapsis(desiredAltitude("Relay"), lastNode:orbit, time:seconds + lastNode:ETA).
		}
	if core:tag:contains("Survey") {
		set lastNode to AlterInclination(90).
		set lastNode to AlterPeriapsis(desiredAltitude("Survey"), lastNode:orbit, time:seconds + lastNode:ETA).
		set lastNode to AlterApoapsis(desiredAltitude("Survey"), lastNode:orbit, time:seconds + lastNode:ETA).
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
	set ship:name to core:tag.
	}

if HasDecoupler {
	print "Waiting for decoupling.".
	wait 30.
	reboot.
	}

print "Clear of launch vehicle?".
wait until NearestVessel:distance > 20.
set kUniverse:timeWarp:Warp to 0.
wait until kUniverse:timeWarp:IsSettled.

print "Equipment deployed?".
if (not panels) {
	deploy.
	}

print "Circularise!".
if hasNode {
	set sasmode to "MANEUVER".
	run execute_next_node.
	}

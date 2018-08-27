runoncepath("orbital_mechanics").

set queue to ship:messages.
set Ship:Control:PilotMainThrottle to 0.

function deploy {
	parameter message.
	set engineFound to false.
	set part to core:part.

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

	if core:tag:contains("Relay") { create_circularise_node(false). }
	if core:tag:contains("Survey") {
		AlterInclination(90).
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
	sas on.
	wait 1.
	set sasmode to "MANEUVER".
	set ship:name to core:tag.
	wait 1. // Give time for KAC to pick up this node.
	runpath("execute_next_node").
	set myConnection to message:sender:connection.
	myConnection:SendMessage("deployed").
	}

function handleMessage {
	parameter message.

	set kUniverse:ActiveVessel to ship.
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
		deploy(thisMessage).
		}
	if thisMessage:content[0] = "apoapsis" {
		set desiredApoapsis to thisMessage:content[1].
		print "Setting apoapsis to " + desiredApoapsis.
		AlterApoapsis(desiredApoapsis, lastOrbit, noEarlierThan).
		}
	if thisMessage:content[0] = "periapsis" {
		set desiredPeriapsis to thisMessage:content[1].
		print "Setting periapsis to " + desiredPeriapsis.
		AlterPeriapsis(desiredPeriapsis, lastOrbit, noEarlierThan).
		}
	if thisMessage:content[0] = "inclination" {
		set desiredInclination to thisMessage:content[1].
		print "Setting inclination to " + desiredInclination.
		AlterInclination(desiredInclination). // FIXME - AlterInclination is fragile on orbits
		}
	}

until false {
	wait 10.
	print "Hello world.".
	if not queue:empty {
		set thisMessage to queue:pop().
		print "Ooh! A message! It says '" + thisMessage:content[0] + "'".
		handleMessage(thisMessage).
		}
	}

// Start with a vessel that has a number of satellites that are attached using decouplers
// Each of the KOS cores is named as "Relay «n»" with a decoupler attaching it to the
// carrier ship.
//
// Deployment occurs in sequence, with one satellite deployed at each periapsis of the resonant orbit.
parameter altitude is orbit:periapsis.

sas on.
wait 1.
set sasmode to "RETROGRADE".
wait until vang(-velocity:orbit, ship:facing:vector) < 0.25.

function NewVessels {
	set myTargets to List().
	set newTargets to List().
	list targets in myTargets.
	for thisThing in myTargets {
		if thisThing:distance < 200 {
			newTargets:add(thisThing).}
		}
	return newTargets.
	}

function LoadProgram {
	parameter kOSPart.
	parameter program.
	set processor to kOSPart:getModule("kOSProcessor").
	set processor:bootfilename to program.
	copypath("0:/" + program, processor:volume:root).
	copypath("0:/orbital_mechanics.ks", processor:volume:root).
	processor:deactivate.
	processor:activate.
	}

function FindDecoupler {
	parameter part.
	set decouplerFound to false.
	until decouplerFound {
		set part to part:parent.
		for module in part:modules {
			if module:matchespattern("decouple"){
				set decouplerPart to part.
				set decouplerModule to part:GetModule(module).
				set decouplerFound to true.
				}
			}
		if not part:HasParent { break. }
		}
	return decouplerModule.
	}

function DecoupleSatellite {
	parameter part.
	set decouplerModule to FindDecoupler(part).
	return decouplerModule:DoEvent("decouple").
	}

set relayCandidates to ship:partstaggedpattern("Relay \d").
if relayCandidates:length > 0 {
	set candidate to relayCandidates[0].
	}
else {
	set surveyCandidates to ship:partstaggedpattern("Survey").
	set candidate to surveyCandidates[0].
	}
LoadProgram(candidate, "relay.ks").

DecoupleSatellite(candidate).
set newTargets to NewVessels.
set newSatellite to newTargets[0].

set myConnection to newSatellite:connection.
wait until newSatellite:distance > 20.
set kuniverse:timewarp:rate to 1.
set message to List("deploy").
myConnection:SendMessage(message).

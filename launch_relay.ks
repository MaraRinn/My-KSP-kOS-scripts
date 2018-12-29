// Start with a vessel that has a number of satellites that are attached using decouplers
// Each of the KOS cores is named as "Relay «n»" with a decoupler attaching it to the
// carrier ship.
//
// Deployment occurs in sequence, with one satellite deployed at each periapsis of the resonant orbit.
parameter altitude is orbit:periapsis.

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
	set requiredFiles to List(program, "orbital_mechanics.ks", "execute_next_node.ks").
	for file in requiredFiles {
		copypath("0:/" + file, processor:volume).
		}
	copypath("0:/lib", processor:volume).
	copypath("0:/boot", processor:volume).
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

set relayCandidates to ship:partstaggedpattern("Relay \d+").
if relayCandidates:length > 0 {
	set candidate to relayCandidates[0].
	print "Loading " + candidate.
	LoadProgram(candidate, "relay.ks").
	}
else {
	set surveyCandidates to ship:partstaggedpattern("Survey").
	set candidate to surveyCandidates[0].
	LoadProgram(candidate, "survey.ks").
	}

DecoupleSatellite(candidate).
wait until kUniverse:ActiveVessel <> ship.
print "Waiting for deployed satellite to return control.".
wait until kUniverse:ActiveVessel = ship.
print "Control has been returned.".
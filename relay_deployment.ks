runoncepath("orbital_mechanics.ks").

sas on.
wait 1.
set sasmode to "RETROGRADE".
set deployPoint to eta:periapsis - 300.
if deployPoint < 0 {
	set deployPoint to deployPoint + orbit:period.
	}
if hasNode {
	run execute_next_node.
	reboot.
	}
else if eta:periapsis < 300 {
	set relayCandidates to ship:partstaggedpattern("Relay \d").
	set surveyCandidates to ship:partstaggedpattern("Survey").
	if (relayCandidates:length > 0 or surveyCandidates:length > 0) {
		run launch_relay.
		reboot.
		}
	set core:bootfilename to "".
	reboot.
	}
else {
	set destinationNode to Node(time:seconds + deployPoint, 0, 0, 0).
	add destinationNode.
	reboot.
	}

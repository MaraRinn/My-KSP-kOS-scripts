runoncepath("orbital_mechanics.ks").

sas on.
wait 1.
set sasmode to "RETROGRADE".
if hasNode {
	run execute_next_node.
	reboot.
	}
else if eta:periapsis < 300 {
	set relayCandidates to ship:partstaggedpattern("Relay \d").
	set surveyCandidates to ship:partstaggedpattern("Survey").
	if (relayCandidates:length > 0 or surveyCandidates:length > 0) {
		run launch_relay.
		set destinationNode to Node(time:seconds + eta:periapsis + ship:orbit:period - 300, 0, 0, 0).
		add destinationNode.
		reboot.
		}
	set core:bootfilename to "".
	reboot.
	}

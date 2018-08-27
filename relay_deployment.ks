runoncepath("orbital_mechanics.ks").

sas on.
wait 1.
set deploying to true.

until not deploying {
	set sasmode to "RETROGRADE".
	set deployPoint to eta:periapsis - 300.
	if deployPoint < 0 { set deployPoint to deployPoint + orbit:period.}
	set destinationNode to Node(time:seconds + deployPoint, 0, 0, 0).
	add destinationNode.
	run execute_next_node.
	run launch_relay.
	set relayCandidates to ship:partstaggedpattern("Relay \d").
	set surveyCandidates to ship:partstaggedpattern("Survey").
	if not (relayCandidates:length > 0 or surveyCandidates:length > 0) {
		set deploying to false.
		}
	}
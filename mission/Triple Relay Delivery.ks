runoncepath("lib/vessel_operations.ks").

lock SunwardVector to -sun:position.

if status = "PRELAUNCH" {
	run launch(140000).
	}
else if HasNode {
	WaitForNode().
	}
else if HasTarget {
	print "FIXME: Please arrange for transfer to " + target:name + " SOI.".
	set targetBody to target.
	wait until body = targetBody.
	}
else {
	runpath("relay_deployment.ks", 3).
	}
reboot.

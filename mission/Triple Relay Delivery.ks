runoncepath("lib/vessel_operations.ks").
if status = "PRELAUNCH" {
	run launch(140000).
	}
else if HasTarget {
	print "FIXME: Please arrange for transfer to " + target:name + " SOI.".
	}
else if HasNode {
	WaitForNode().
	}
else {
	runpath("relay_deployment.ks", 3).
	}
reboot.

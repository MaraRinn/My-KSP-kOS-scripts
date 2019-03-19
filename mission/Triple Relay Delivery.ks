runoncepath("lib/vessel_operations.ks").
runoncepath("orbital_mechanics.ks").

lock sunwardVector to -sun:position.

if status = "PRELAUNCH" {
	print "Please select a target for this relay delivery.".
	wait until HasTarget.
	print "Launching!".
	run launch(140000).
	}
else if HasNode {
	WaitForNode(sunwardVector).
	}
else if HasTarget {
	if orbit:HasNextPatch and orbit:NextPatch:body = target {
		print "Chilling out until " + target:name + " SOI.".
		WaitForAlarm().
		}
	else {
		print "FIXME: Please arrange for transfer to " + target:name + " SOI.".
		set targetBody to target.
		wait until body = targetBody.
		}
	}
else if apoapsis < 0 {
	// No target so we are in the target body's SOI, on an escape trajectory.
	set kspSoiLimit to body:soiradius * 0.95 - body:radius.
	print "Apoapsis after capture: " + kspSoiLimit.
	AlterApoapsis(kspSoiLimit).
	}
else {
	runpath("relay_deployment.ks", 3).
	}
reboot.

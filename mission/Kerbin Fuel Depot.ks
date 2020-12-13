// Customisation for Kerbin Fuel Depot
print "Initialising Kerbin Fuel Depot".
runoncepath("orbital_mechanics.ks").
runoncepath("lib/vessel_operations.ks").

// Overall objective:
//   - keep station on a 100km orbit around Kerbin
//   - attitude locked to normal vector with no rotation

set StationAltitude to 100_000.

if HasNode {
	if NextNode:ETA < 0 {
		remove NextNode.
		wait 0.1.
		reboot.
		}
	ExecuteNextNode().
	}

if orbit:body = Kerbin {
	if status = "PRELAUNCH" or apoapsis < MinimumSafePeriapsis() {
			print "Ready to launch! Press 6 to launch.".
			wait until AG6.
			set lp to Lexicon("altitude", StationAltitude, "inclination" , 0, "launch pitch", 75, "time to apoapsis", 50).
			runpath("launch_cta.ks", lp).
			reboot.
		}

	if    abs(apoapsis - StationAltitude) < 1000 and
			abs(periapsis - StationAltitude) < 1000 and
			abs(orbit:inclination < 0.1) {
		print "Station Keeping.".
		panels on.
		sas off.
		wait 1.
		rcs off.
		sas on.
		wait 1.
		set sasmode to "NORMAL".
		}

	else if abs(apoapsis - StationAltitude) >= 1000 {
		print "Adjusting Apoapsis.".
		AlterApoapsis(StationAltitude).
		}

	else if abs(periapsis - StationAltitude) >= 1000 {
		print "Adjusting Periapsis.".
		AlterPeriapsis(StationAltitude).
		}

	else if abs(orbit:inclination) > 0.05 {
		print "Adjusting Inclination.".
		AlterInclination(0).
		}
	}

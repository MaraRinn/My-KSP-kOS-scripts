// Customisation for 7m Fuel Transport (HS)
print "Initialising 7m Fuel Transport (HS)".
runoncepath("orbital_mechanics.ks").
runpath("lib/vessel_operations.ks").

set SteeringManager:MaxStoppingTime to 3.
set minmusTransferFuel to 6800. // Roughly enough fuel to get to Minmus and rendezvous with the station there
set zeroAltitude to 45. // Metres altitude when landed.

if mass > 500 {
	rcs on.
	}
else {
	rcs off.
	}

function Fillup {
	runpath("fueltohauler").
	}

function Dump {
	set haulerFuel to minmusTransferFuel.
	runpath("fueltostation", haulerFuel, true).
	}

function ConfigureForAerobraking {
	print " ** Batten down the hatches, aerobraking ahead **".
	set checkNode to Node(time:seconds + eta:periapsis, 0, 0, 0).
	add checkNode.
	rcs on.
	sas on.
	wait 1.
	set sasmode to "PROGRADE".
	wait until altitude < 100000.
	set kUniverse:TimeWarp:Warp to 0.
	wait until NextNode:ETA < 0 and altitude > 70000.
	remove NextNode.
	print " (aerobraking manoeuvre completed) ".
	}

if HasNode and NextNode:ETA < 0 {
	remove NextNode.
	wait 0.1.
	}

if HasNode {
	if round(NextNode:deltaV:mag) = 0 and orbit:body = Kerbin and orbit:periapsis < orbit:body:atm:height {
		ConfigureForAerobraking.
		reboot.
		}
	print "** Waiting for manoeuvre **".
	wait until not HasNode.
	reboot.
	}
else if orbit:body = Minmus and fuelPercent() < 10 {
	print "In orbit of Minmus with no fuel, getting ready to land.".
	// get into a 10km equatorial orbit
	if orbit:apoapsis < 0 {
		print " - capturing from insertion to orbit".
		run "capture_from_insertion".
		wait until not HasNode.
		reboot.
		}
	else if round(orbit:inclination) <> 0 {
		print " - altering inclination to 0".
		AlterInclination(0).
		wait until not HasNode.
		reboot.
		}
	else if round(orbit:apoapsis/1000) <> 10 {
		print " - altering apoapsis to 10km".
		AlterApoapsis(10000).
		wait until not HasNode.
		reboot.
		}
	else if round(orbit:periapsis/1000) <> 10 {
		print " - altering periapsis to 10km".
		AlterPeriapsis(10000).
		wait until not HasNode.
		reboot.
		}
	else {
		set target to Vessel("Minmus Fuel Base").
		print " (( Ready to perform landing ))".
		}
	}
else if orbit:body = Minmus and fuelPercent() > 80 {
	print "In orbit of Minmus with a load of fuel, should be heading back to Kerbin.".
	if orbit:HasNextPatch and orbit:NextPatch:Body = Kerbin {
		print " ** Chilling out until Kerbin SOI ** ".
		wait until orbit:body = Kerbin.
		reboot.
		}
	else if round(orbit:apoapsis/1000) < 8 and round(orbit:periapsis/1000) < 8 {
		print " ** raising apoapsis to 8km ".
		sas on.
		wait 0.1.
		set sasmode to "PROGRADE".
		set throttle to 1.
		wait until round(orbit:apoapsis/1000) >= 8.
		set throttle to 0.
		reboot.
		}
	else if round(orbit:periapsis/1000) < 20 {
		print " ** raising periapsis to 20km ** ".
		AlterPeriapsis(20000).
		wait until not HasNode.
		reboot.
		}
	else if round(orbit:apoapsis/1000) < 20 {
		print " raising apoapsis to 20km ** ".
		AlterApoapsis(20000).
		wait until not HasNode.
		reboot.
		}
	else {
		print " (( FIXME - plot return from Minmus to Kerbin with 36km periapsis )) ".
		}
	}
else if orbit:body = Minmus {
	print "In orbit of Minmus, but what is happening?".
	}
else if orbit:body = Kerbin and fuelPercent() > 80 {
	print "In orbit of Kerbin, mission is to dock with fuel station.".
	if round(orbit:inclination) <> 0 {
		print " - altering inclination to 0".
		AlterInclination(0).
		}
	else if orbit:apoapsis > 600000 {
		print " - coarse aerobraking phase".
		if round(orbit:periapsis / 1000) <> 36 and eta:periapsis > eta:apoapsis {
			print " ** altering next periapsis to 36km for aerobraking **".
			AlterPeriapsis(36000).
			sas off.
			wait until not HasNode.
			reboot.
			}
		else if round(orbit:periapsis / 1000) <> 36 {
			print " ** FIXME: adjust periapsis to 36km before we get there **".
			wait until round(orbit:periapsis / 1000) = 36.
			reboot.
			}
		else {
			ConfigureForAerobraking.
			reboot.
			}
		}
	else if orbit:apoapsis > 250000 {
		print " - fine aerobraking phase".
		if round(orbit:periapsis / 1000) <> 45 and eta:periapsis > eta:apoapsis {
			print " ** altering next periapsis to 45km for aerobraking ** ".
			AlterPeriapsis(45000).
			sas off.
			wait until not HasNode.
			reboot.
			}
		else if round(orbit:periapsis / 1000) <> 45 {
			print " ** FIXME: adjust periapsis to 45km before we get there ** ".
			wait until round(orbit:periapsis / 1000) = 45.
			reboot.
			}
		else {
			ConfigureForAerobraking.
			reboot.
			}
		}
	else {
		print " - orbital phase".
		if round(orbit:periapsis / 1000) <> round(orbit:apoapsis / 1000) {
			print " ** circularising **".
			create_circularise_node().
			wait until not HasNode.
			reboot.
			}
		else {
			set target to Vessel("Kerbin Fuel Station").
			print " (( Ready to perform rendezvous ))".
			}
		}
	}
else if orbit:body = Kerbin and fuelPercent() < 20 {
	print "Orbiting Kerbin but heading for Minmus".
	set target to Minmus.
	if orbit:periapsis < body:atm:height {
		print " ** Raising periapsis out of atmosphere. You might want to take over.".
		AlterPeriapsis(80000).
		wait until orbit:periapsis > body:atm:height.
		reboot.
		}
	if orbit:apoapsis < 1000000 {
		print " ** in-plane component of rendezvous **".
		run Rendezvous.
		wait until not HasNode.
		reboot.
		}
	if orbit:HasNextPatch and orbit:NextPatch:Body = Minmus {
		print " ** Chilling out until Minmus ** ".
		wait until orbit:body = Minmus.
		reboot.
		}
	if orbit:apoapsis > 1000000 {
		print " ** Waiting for manual mid-course correction ** ".
		print " ** FIXME: please add mid-course correction ** ".
		wait until orbit:HasNextPatch.
		reboot.
		}
	}
else if orbit:body = Kerbin {
	print "In orbit of Kerbin, but what is happening?".
	}

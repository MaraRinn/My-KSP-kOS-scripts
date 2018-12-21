// Customisation for 7m Fuel Transport (HS)
print "Initialising 7m Fuel Transport (HS)".
runoncepath("orbital_mechanics.ks").
runoncepath("lib/vessel_operations.ks").

set SteeringManager:MaxStoppingTime to 5.
set minmusTransferFuel to 6800. // Roughly enough fuel to get to Minmus and rendezvous with the station there

if mass > 500 {
	rcs on.
	}
else {
	rcs off.
	}

function ConfigureForAerobraking {
	parameter brakingAltitude.

	set altInKM to round(orbit:periapsis / 1000).
	set brakeAltInKM to round(brakingAltitude / 1000).
	if altInKM <> brakeAltInKM {
		if (eta:periapsis > eta:apoapsis) or (orbit:periapsis > body:atm:height) {
			print " ** altering next periapsis to " + brakeAltInKM + "km for aerobraking ** ".
			AlterPeriapsis(brakingAltitude).
			sas off.
			wait until not HasNode.
			}
		else {
			print " ((FIXME: adjust periapsis to " + brakeAltInKM + "km before getting there)) ".
			wait until round(orbit:periapsis / 1000) = brakeAltInKM.
			}
		reboot.
		}
	print " ** Batten down the hatches, aerobraking ahead **".
	set checkNode to Node(time:seconds + eta:periapsis, 0, 0, 0).
	add checkNode.
	rcs off.
	sas off.
	kUniverse:QuickSaveTo("Preparing for aerobraking").
	wait until altitude < 100000.
	set kUniverse:TimeWarp:Warp to 0.
	wait until kUniverse:TimeWarp:IsSettled.
	sas off.
	rcs on.
	lock steering to prograde.
	print " - transferring fuel to forward tank".
	set transferTank to ship:partsdubbed("Transfer Tank").
	set vesselFuel to ship:partsdubbed("Vessel Fuel").
	set oxidizerTransfer to TransferAll("OXIDIZER", transferTank, vesselFuel).
	set oxidizerTransfer:ACTIVE to true.
	set fuelTransfer to TransferAll("LIQUIDFUEL", transferTank, vesselFuel).
	set fuelTransfer:ACTIVE to true.
	wait until not oxidizerTransfer:ACTIVE.
	wait until not fuelTransfer:ACTIVE.
	wait until NextNode:ETA < 0 and altitude > 70000.
	remove NextNode.
	unlock steering.
	print " (aerobraking manoeuvre completed) ".
	reboot.
	}

list elements in elementList.
if elementList:length > 1 {
	print " (( Currently docked )) ".
	// should verify that this ship is docked to Kerbin Fuel Station
	if status = "ORBITING" and body = Kerbin {
		fuelToStation("7m Fuel Transport", minmusTransferFuel, true).
		undock("7m Fuel Transport").
		reboot.
		}
	if status = "LANDED" and body = Minmus {
		print " (( Landed on Minmnus and connected to something, Press 5 to launch )) ".
		wait until AG5.
		reboot.
		}
	}

if HasNode and NextNode:ETA < 0 {
	remove NextNode.
	wait 0.1.
	}

if HasNode {
	if round(NextNode:deltaV:mag) = 0 and orbit:body = Kerbin and orbit:periapsis < orbit:body:atm:height {
		ConfigureForAerobraking(orbit:periapsis).
		}
	print "** Waiting for manoeuvre ** ".
	wait until not HasNode.
	reboot.
	}
else if orbit:body = Mun {
	print "Attempting to manage Mun fly-by".
	if orbit:periapsis < 14000 {
		print " - raising periapsis to avoid collision".
		sas on.
		rcs on.
		wait 1.
		set sasmode to "RADIALOUT".
		wait 1.
		wait until ship:angularvel:mag < 0.2.
		set throttle to 0.1.
		wait until orbit:periapsis > 14000.
		set throttle to 0.
		set sasmode to "NORMAL".
		}
	print " (( Chilling out until Kerbin SOI )) ".
	sas on.
	rcs off.
	wait 1.
	set sasmode to "NORMAL".	
	wait until orbit:Body = Kerbin.
	reboot.
	}
else if orbit:body = Minmus and fuelPercent() <= 80 {
	// get into a 10km equatorial orbit
	if status = "LANDED" {
		print " (( Waiting for fuel loading )) ".
		wait until fuelPercent() > 99.
		reboot.
		}
	print "In orbit of Minmus with no fuel, getting ready to land.".
	if orbit:apoapsis < 0 {
		if orbit:periapsis > 7000 {
			print " - lowering periapsis".
			sas on.
			rcs on.
			wait 1.
			set sasmode to "RADIALIN".
			wait 1.
			wait until ship:angularvel:mag < 0.02.
			set throttle to 0.1.
			wait until orbit:periapsis <= 7000.
			set throttle to 0.
			set sasmode to "STABILITY".
			}
		else if orbit:periapsis < 6000 {
			print " - raising periapsis".
			sas on.
			rcs on.
			wait 1.
			set sasmode to "RADIALOUT".
			wait 1.
			wait until ship:angularvel:mag < 0.2.
			set throttle to 0.1.
			wait until orbit:periapsis > 6000.
			set throttle to 0.
			set sasmode to "STABILITY".
			}
		else {
			print " - capturing from insertion to orbit".
			run "capture_from_insertion".
			print "** Waiting for manoeuvre **".
			wait until not HasNode.
			}
		reboot.
		}
	else if round(orbit:inclination) <> 0 {
		print " - altering inclination to 0".
		AlterInclination(0).
		print " ** Waiting for manoeuvre ** ".
		wait until not HasNode.
		reboot.
		}
	else if round(orbit:apoapsis/1000) <> 10 {
		print " - altering apoapsis to 10km".
		AlterApoapsis(10000).
		print "** Waiting for manoeuvre **".
		wait until not HasNode.
		reboot.
		}
	else if round(orbit:periapsis/1000) <> 10 {
		print " - altering periapsis to 10km".
		AlterPeriapsis(10000).
		print "** Waiting for manoeuvre **".
		wait until not HasNode.
		reboot.
		}
	else {
		set target to Vessel("Minmus Fuel Base").
		print " (( Ready to perform landing ))".
		}
	}
else if orbit:body = Minmus and fuelPercent() > 80 {
	print "At Minmus with fuel, should be heading back to Kerbin.".
	if ship:status = "LANDED" {
		print " ** Launching to 20km orbit **".
		print " ** Press 6 to launch ** ".
		wait until AG6.
		runpath("launch.ks", 20000).
		reboot.
		}
	else if orbit:HasNextPatch and orbit:NextPatch:Body = Kerbin {
		print " (( Chilling out until Kerbin SOI )) ".
		rcs off.
		sas on.
		wait 0.1.
		set sasmode to "NORMAL". // Ensure solar panels are lit
		wait until orbit:body = Kerbin.
		reboot.
		}
	else if round(orbit:apoapsis/1000) < 8 {
		print " ** raising apoapsis to 8km ** ".
		sas off.
		lock steering to heading(90,45).
		set throttle to 1.
		wait until round(orbit:apoapsis/1000) >= 8.
		set throttle to 0.
		unlock steering.
		reboot.
		}
	else if round(orbit:periapsis/1000) < 20 {
		print " ** raising periapsis to 20km ** ".
		AlterPeriapsis(20000).
		wait until not HasNode.
		reboot.
		}
	else if round(orbit:apoapsis/1000) < 20 {
		print " ** raising apoapsis to 20km ** ".
		AlterApoapsis(20000).
		wait until not HasNode.
		reboot.
		}
	else {
		print " (( FIXME - plot return from Minmus to Kerbin with 36km periapsis )) ".
		wait until orbit:HasNextPatch.
		reboot.
		}
	}
else if orbit:body = Minmus {
	print "In orbit of Minmus, but what is happening?".
	}
else if orbit:body = Kerbin and status = "PRELAUNCH" {
		print "Ready to launch! Press 6 to launch.".
		wait until AG6.
		runpath("launch.ks", 130000).
		stage.
		reboot.
	}
else if orbit:body = Kerbin and (fuelPercent() > 20 or fuel:amount < minmusTransferFuel) {
	print "Kerbin, with fuel.".
	if orbit:HasNextPatch and orbit:NextPatch:Body = Minmus {
		print " (( Chilling out until Minmus SOI )) ".
		rcs off.
		sas on.
		wait 0.1.
		set sasmode to "NORMAL".
		wait until orbit:Body = Minmus.
		reboot.
		}
	if orbit:HasNextPatch and orbit:NextPatch:Body = Mun {
		print " (( Chilling out until Mun SOI )) ".
		rcs off.
		sas on.
		wait 0.1.
		set sasmode to "NORMAL".
		wait until orbit:Body = Mun.
		reboot.
		}
	else if round(orbit:inclination) <> 0 {
		print " - altering inclination to 0".
		AlterInclination(0).
		reboot.
		}
	else if orbit:apoapsis > 40000000 {
		print " - braking from high speed".
		// FIXME: these values are entirely arbitrary and should scale:
		//  - (square? cube? linear?) to velocity at periapsis (density of atmosphere -> drag force -> torque)
		//  - centre of mass versus centre of drag (torque moment)
		//  - could also configure craft with more RCS thrusters at rear?
		ConfigureForAerobraking(45000).
		}
	else if orbit:apoapsis > 600000 {
		print " - coarse aerobraking phase".
		ConfigureForAerobraking(36000).
		}
	else if orbit:apoapsis > 250000 {
		print " - fine aerobraking phase".
		ConfigureForAerobraking(45000).
		}
	else if orbit:periapsis < 100000 {
		print " - raise periapsis out of atmosphere".
		AlterPeriapsis(100000).
		}
	else {
		print " - rendezvous phase".
		set target to Vessel("Kerbin Fuel Station").
		print " (( Ready to perform rendezvous ))".
		}
	reboot.
	}
else if orbit:body = Kerbin {
	print "Orbiting Kerbin, heading for Minmus".
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
		clearscreen.
		print "** Waiting for manoeuvre ** ".
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
		print " ** FIXME: please add mid-course correction to intercept Minmus ** ".
		wait until orbit:HasNextPatch.
		reboot.
		}
	}
else if orbit:body = Kerbin {
	print "In orbit of Kerbin, but what is happening?".
	}
reboot.

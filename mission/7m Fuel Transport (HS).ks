// Customisation for 7m Fuel Transport (HS)
print "Initialising 7m Fuel Transport (HS)".
runoncepath("orbital_mechanics.ks").
runoncepath("lib/vessel_operations.ks").

set SteeringManager:MaxStoppingTime to 3.5.
set minmusTransferFuel to 7300. // Roughly enough fuel to get to Minmus and rendezvous with the station there

rcs on.

function ConfigureForAerobraking {
	parameter brakingAltitude.

	set altInKM to round(orbit:periapsis / 1000).
	set brakeAltInKM to round(brakingAltitude / 1000).
	if altInKM <> brakeAltInKM {
		if (eta:periapsis > eta:apoapsis) or (orbit:periapsis > body:atm:height) {
			print " ** altering next periapsis to " + brakeAltInKM + "km for aerobraking ** ".
			AlterPeriapsis(brakingAltitude).
			sas off.
			return.
			}
		else {
			print " ((FIXME: adjust periapsis to " + brakeAltInKM + "km before getting there)) ".
			wait until round(orbit:periapsis / 1000) = brakeAltInKM.
			}
		}
	print " ** Batten down the hatches, aerobraking ahead **".
	set checkNode to Node(time:seconds + eta:periapsis, 0, 0, 0).
	add checkNode.
	sas off.
	kUniverse:QuickSaveTo("Preparing for aerobraking").
	wait until altitude < 120000 and eta:periapsis < eta:apoapsis.
	set kUniverse:TimeWarp:Warp to 0.
	wait until kUniverse:TimeWarp:IsSettled.
	sas off. // Using KOS cooked steering because SAS relies on probe control, which is disrupted by aerobraking plasma
	rcs on.
	lock steering to prograde.
	panels off.
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
	panels on.
	print " (aerobraking manoeuvre completed) ".
	}

function ConfigureChillMode {
	panels on.
	}

list elements in elementList.
if elementList:length > 1 {
	print " (( Currently docked )) ".
	// should verify that this ship is docked to Kerbin Fuel Station
	if status = "ORBITING" and body = Kerbin {
		fuelToStation("7m Fuel Transport", minmusTransferFuel, true).
		undock("7m Fuel Transport").
		}
	if status = "LANDED" and body = Minmus {
		print " (( Landed on Minmnus and connected to something, Press 5 to launch )) ".
		wait until AG5.
		}
	}

if HasNode and NextNode:ETA < 0 {
	remove NextNode.
	wait 0.1.
	}

if HasNode {
	if round(NextNode:deltaV:mag) = 0 and orbit:body = Kerbin and orbit:periapsis < orbit:body:atm:height {
		if eta:periapsis < eta:apoapsis {
			ConfigureForAerobraking(orbit:periapsis).
			}
		else {
			set checkNode to Node(time:seconds + eta:periapsis, 0, 0, 0).
			add checkNode.
			}
		}
	else {
		print " (( Waiting for Manoeuvre )) ".
		WaitForNode().
		}
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
	ConfigureChillMode.	
	wait until orbit:Body = Kerbin.
	}
else if orbit:body = Minmus and fuelPercent() <= 80 {
	// get into a 10km equatorial orbit
	if status = "LANDED" {
		print " (( Waiting for fuel loading )) ".
		wait until fuelPercent() > 99.
		}
	else if altitude < 20 and ship:velocity:surface:mag < 5 {
		print " (( Are we bouncing after physics load? ))".
		gear on.
		wait until status = "LANDED".
		}
	else if fuelPercent() = 0 {
		print " (( out of fuel ))  ".
		wait until fuelPercent() > 2.
		}
	else if orbit:apoapsis < 0 {
		print " (( On hyperbolic trajectory past Minmus )) ".
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
			print " (( Waiting for manoeuvre )) ".
			WaitForNode().
			}
		}
	else if round(orbit:inclination) <> 0 {
		print " - altering inclination to 0".
		AlterInclination(0).
		print " (( Waiting for manoeuvre )) ".
		WaitForNode().
		}
	else if round(orbit:apoapsis/1000) <> 10 {
		print " - altering apoapsis to 10km".
		AlterApoapsis(10000).
		print " (( Waiting for manoeuvre )) ".
		WaitForNode().
		}
	else if round(orbit:periapsis/1000) <> 10 {
		print " - altering periapsis to 10km".
		AlterPeriapsis(10000).
		print " (( Waiting for manoeuvre )) ".
		WaitForNode().
		}
	else {
		set target to Vessel("Minmus Fuel Base").
		print " ** Please land at the fuel base ** ".
		wait until ship:velocity:surface:mag < 0.1.
		}
	}
else if orbit:body = Minmus and fuelPercent() > 80 {
	print "At Minmus with fuel, should be heading back to Kerbin.".
	if ship:status = "LANDED" {
		print " ** Launching to 20km orbit **".
		print " ** Press 6 to launch ** ".
		wait until AG6.
		runpath("launch.ks", 20000).
		}
	else if orbit:HasNextPatch and orbit:NextPatch:Body = Kerbin {
		print " (( Chilling out until Kerbin SOI )) ".
		ConfigureChillMode().
		wait until orbit:body = Kerbin.
		}
	else if round(orbit:apoapsis/1000) < 8 {
		print " ** raising apoapsis to 8km ** ".
		sas off.
		lock steering to heading(90,45).
		set throttle to 1.
		wait until round(orbit:apoapsis/1000) >= 8.
		set throttle to 0.
		unlock steering.
		}
	else if round(orbit:periapsis/1000) < 20 {
		print " ** raising periapsis to 20km ** ".
		AlterPeriapsis(20000).
		WaitForNode().
		}
	else if round(orbit:apoapsis/1000) < 20 {
		print " ** raising apoapsis to 20km ** ".
		AlterApoapsis(20000).
		wait until not HasNode.
		}
	else {
		print " (( FIXME - plot return from Minmus to Kerbin with 36km periapsis )) ".
		wait until orbit:HasNextPatch.
		wait 10.
		}
	}
else if orbit:body = Minmus {
	print "In orbit of Minmus, but what is happening?".
	}
else if orbit:body = Kerbin and status = "PRELAUNCH" {
		print "Ready to launch! Press 6 to launch.".
		wait until AG6.
		set lp to Lexicon("altitude", 80000, "inclination" , 0, "launch pitch", 75, "time to apoapsis", 50).
		runpath("launch_cta.ks", lp).
		stage.
	}
else if orbit:body = Kerbin and (not orbit:HasNextPatch) and (fuelPercent() > 20) {
	print "Kerbin.".
	if orbit:HasNextPatch and orbit:NextPatchEta < eta:Periapsis and orbit:NextPatch:Body = Minmus {
		print " (( Chilling out until Minmus SOI )) ".
		ConfigureChillMode().
		wait until orbit:Body = Minmus.
		}
	if orbit:HasNextPatch and orbit:NextPatchEta < eta:Periapsis and orbit:NextPatch:Body = Mun {
		print " (( Chilling out until Mun SOI )) ".
		ConfigureChillMode().
		wait until orbit:Body = Mun.
		}
	else if round(orbit:inclination) <> 0 {
		print " - altering inclination to 0".
		AlterInclination(0).
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
	else if orbit:periapsis < 71000 {
		print " - raise periapsis out of atmosphere".
		AlterPeriapsis(80000).
		}
	else if orbit:apoapsis > 85000 and abs(orbit:apoapsis - orbit:periapsis) > 1000 {
		print " - circularise orbit".
		create_circularise_node(false).
		}
	else {
		print " - rendezvous phase".
		set target to Vessel("Kerbin Fuel Depot").
		print " ** Over to you to perform rendezvous ** ".
		wait until false.
		}
	}
else if orbit:body = Kerbin {
	print "Orbiting Kerbin, heading for Minmus".
	if orbit:HasNextPatch and orbit:NextPatch:Body = Minmus {
		print " (( Chilling out until Minmus )) ".
		ConfigureChillMode().
		wait until orbit:body = Minmus.
		}
	if orbit:HasNextPatch and orbit:NextPatch:Body = Mun {
		print " (( Chilling out until Mun )) ".
		ConfigureChillMode().
		wait until orbit:body = Mun.
		}
	if orbit:apoapsis > 40_000_000 {
		print " ** Mid-course Correction ** ".
		runpath("midcourse_correction.ks").
		}
	if orbit:periapsis < body:atm:height {
		print " ** Raising periapsis out of atmosphere. You might want to take over.".
		AlterPeriapsis(80000).
		wait until orbit:periapsis > body:atm:height.
		}
	else if fuelPercent() < 2 {
		print " - out of fuel".
		sas on.
		wait 0.1.
		set sasmode to "STABILITY".
		print " ** waiting for refuelling operation ** ".
		set docked to false.
		until docked {
			list elements in elementList.
			clearscreen.
			print " ** Waiting for refuelling to start ** ".
			print "Current Elements:".
			print elementList.
			if elementList:length > 1 {
				set docked to true.
				print "Someone docked!".
				}
			wait 60.
			}
		until not docked {
			list elements in elementList.
			clearscreen.
			print " ** Waiting for refuelling to end ** ".
			print "Current Elements:".
			print elementList.
			if elementList:length = 1 {
				set docked to false.
				print "They're gone!".
				}
			wait 60.
			}
		}
	if orbit:apoapsis < 2000000 {
		print " ** in-plane component of rendezvous **".
		set target to Minmus.
		run Rendezvous.
		if orbit:HasNextPatch and orbit:NextPatch:Body = Mun {
			print " (( Mun is in the way, waiting a couple of orbits )) ".
			remove nextnode.
			AddAlarm("Raw", time:seconds + orbit:period, "Planning Rendezvous", ship:name + " is headed to Minmus. Mun was in the way, maybe now it's not").
			wait orbit:period.
			}
		else {
			wait 2.
			clearscreen.
			print "** Waiting for manoeuvre ** ".
			rcs on.
			sas off.
			WaitForNode().
			}
		}
	else {
		print " ** Not sure what's happening, please arrange a rendezvous with Minmus ** ".
		wait until orbit:HasNextPatch.
		}
	}
else {
	print "What is happening? Please get me to Kerbin or Mun SOI".
	ConfigureChillMode().
	wait until orbit:HasNextPatch.
	}
wait 5.
reboot.

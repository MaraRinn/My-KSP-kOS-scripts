LIST RESOURCES IN RESLIST.
set hasCharge to false.
set hasOre to false.
set hasFuel to false.
set hasOxidizer to false.

FOR RES IN RESLIST {
	if RES:NAME = "ElectricCharge" {
		set charge to RES.
		lock chargePercent to round(100 * charge:amount / charge:capacity).
		set hasCharge to true.
		}
	if RES:NAME = "Ore" {
		set ore to RES.
		lock orePercent to round(100 * ore:amount / ore:capacity).
		set hasOre to true.
		}
	if RES:NAME = "LiquidFuel" {
		set fuel to RES.
		lock fuelPercent to round(100 * fuel:amount / fuel:capacity).
		set hasFuel to true.
		}
	if RES:NAME = "Oxidizer" {
		set oxidizer to RES.
		lock oxidizerPercent to round(100 * oxidizer:amount / oxidizer:capacity).
		set hasOxidizer to true.
		}
	}

function elementWithName {
	parameter name.

	list elements in elementList.
	set iter to elementList:iterator.
	
	until not iter:next {
		if iter:value:name:contains(name) {
			return iter:value.
			}
		}
	return "No element with name " + name + " found.".
	}

function fuelToStation {
	PARAMETER elementName.
	PARAMETER vesselFuelQty.
	PARAMETER needsOxidizer.

	set tanker to elementWithName(elementName).
 
	set shipTransferTanks to ship:partsdubbed("Transfer Tank").
	set fuelStorage to ship:partsdubbed("Fuel Storage").
	set minerFuel to ship:partsdubbed("Miner Fuel").
	set shipVesselFuels to ship:partsdubbed("Vessel Fuel").
	for tank in minerFuel {
		shipVesselFuels:add(tank).
		}

	set transferTank to List().
	for tank in shipTransferTanks {
		if tanker:parts:contains(tank) {
			transferTank:add(tank).
			}
		}
	set vesselFuel to List().
	for tank in shipVesselFuels {
		if tanker:parts:contains(tank) {
			vesselFuel:add(tank).
			}
		}

	// Find our Monopropellant.
	set monoStorage to ship:partsdubbed("Monopropellant Storage").
	set monoFuel to list().
	for part in ship:parts {
		// We're going to take all the monopropellant from everywhere
		if part:tag <> "Monopropellant Storage" {
			for resource in part:resources {
				if resource:name = "MONOPROPELLANT" and resource:capacity > 0 {
					monoFuel:add(part).
					}
				}
			}
		}

	print "Take all the resources from the transport ship.".
	print " - transfer tank".
	set oxidizerTransfer to TRANSFERALL("OXIDIZER", transferTank, fuelStorage).
	set oxidizerTransfer:ACTIVE to true.

	set fuelTransfer to TRANSFERALL("LIQUIDFUEL", transferTank, fuelStorage).
	set fuelTransfer:ACTIVE to true.

	wait until not oxidizerTransfer:ACTIVE.
	wait until not fuelTransfer:ACTIVE.

	print " - fuel tanks".
	set oxidizerTransfer to TRANSFERALL("OXIDIZER", vesselFuel, fuelStorage).
	set oxidizerTransfer:ACTIVE to true.

	set fuelTransfer to TRANSFERALL("LIQUIDFUEL", vesselFuel, fuelStorage).
	set fuelTransfer:ACTIVE to true.

	if monoFuel:length > 0 {
		print " - mono propellant".
		set monoTransfer to TRANSFERALL("MONOPROPELLANT", monoFuel, monoStorage).
		set monoTransfer:ACTIVE to true.
		wait until not monoTransfer:ACTIVE.
		}

	wait until not fuelTransfer:ACTIVE.
	wait until not oxidizerTransfer:ACTIVE.


	print "".
	print "Refuelling transport ship:      ".
	print " - " + vesselFuelQty + " fuel    ".
	set fuelTransfer to TRANSFER("LIQUIDFUEL", fuelStorage, vesselFuel, vesselFuelQty).
	set fuelTransfer:ACTIVE to true.
	wait until not fuelTransfer:ACTIVE.

	if needsOxidizer {
		set oxidizerQty to round(vesselFuelQty * 1.222, 0).
		print " - " + oxidizerQty + " oxidizer     ".
		set oxidizerTransfer to TRANSFER("OXIDIZER", fuelStorage, vesselFuel, oxidizerQty).
		set oxidizerTransfer:ACTIVE to true.
		wait until not oxidizerTransfer:ACTIVE.
		}

	print "Thank you for visiting, have a nice day!".
	}

function undock {
	parameter elementName.
	set self to elementWithName(elementName).
	for port in self:DockingPorts {
		port:undock.
		}
	wait 1.
	set kUniverse:ActiveVessel to core:vessel.
	}

function HasAlarm {
	set alarms to ListAlarms("All").
	return (alarms:length > 0).
	}

// Honour Kerbal Alarm Clock
function KACAlarmWithin {
	parameter seconds.
	if addons:available("KAC") {
		for alarm in addons:KAC:Alarms {
			if alarm:remaining > 0 and alarm:remaining <= seconds { return true. }
			}
		}
	return false.
	}

function NextKACAlarm {
	set remaining to 999999.
	for alarm in addons:KAC:Alarms {
		if alarm:remaining < remaining {
			set remaining to alarm:remaining.
			set nextAlarm to alarm.
			}
		}
	return nextAlarm.
	}

// Warping
function WarpToTime {
	parameter destinationTime.
	set ratesList to kUniverse:timeWarp:RailsRateList.
	until time:seconds >= destinationTime {
		set interval to destinationTime - time:seconds.
		// It takes about 1 real second to speed up or slow down warp.
		from { set i to ratesList:Length - 1. } until (ratesList[i] < (interval)) or (i = 0) step { set i to i - 1.} do { }.
		set kUniverse:timeWarp:Warp to i.
		wait 0.1.
		set warpInterval to ratesList[kUniverse:timeWarp:Warp].
		set waitTime to time:seconds + warpInterval - 1.
		if KACAlarmWithin(warpInterval) {
			print "Waiting for KAC alarm.".
			wait until time:seconds > time:seconds + NextKACAlarm:remaining + 5.
			}
		else {
			wait until time:seconds >= waitTime.
			}
		if kUniverse:ActiveVessel <> ship {
			break.
			}
		}
	set kUniverse:timeWarp:Warp to 0.
	wait until kUniverse:timeWarp:IsSettled.
	}

function WaitForAlarm {
	set soonest to NextKACAlarm().
	print "Waiting for alarm in " + round(soonest:remaining) + " seconds.".
	set warpEndTime to time:seconds + soonest:remaining.
	WarpToTime(warpEndTime).
	DeleteAlarm(soonest:id).
	}

function WaitForNode {
	// if the next node is due soon enough, perform it otherwise sit here waiting
	lock acceleration to ship:maxthrust / ship:mass.
	lock burnDuration to NextNode:burnvector:mag / acceleration.
	lock burnETA to NextNode:eta - (burnDuration/2 + 1).
	set soonest to NextKACAlarm().
	set warpEndTime to time:seconds + soonest:remaining.

	if burnETA > 300 {
		print "Waiting for next manoeuvre in " + round(burnETA) + " seconds.".
		WarpToTime(warpEndTime).
		if (soonest:type <> "Maneuver") and (soonest:type <> "ManeuverAuto") {
			DeleteAlarm(soonest:id).
			}
		wait until burnETA <= 300.
		}

	run "execute_next_node".
	}

function WithinError {
	parameter A.
	parameter B.
	parameter relativeErrorAllowed is 0.01.

	set absoluteError to abs(B - A).
	set relativeError to absoluteError / B.
	print "Absolute Error: " + round(absoluteError).
	print "Relative Error: " + round(relativeError,2).
	if (relativeError <= relativeErrorAllowed) {
		return true.
		}
	return false.
	}

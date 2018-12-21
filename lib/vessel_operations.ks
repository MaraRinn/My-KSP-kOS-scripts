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

function NextAlarmIsMine {
	set shortestRemaining to 0.
	for alarm in Addons:KAC:Alarms {
		if shortestRemaining = 0 or shortestRemaining > alarm:remaining {
			set shortestRemaining to alarm:remaining.
			set soonestAlarm to alarm.
			}
		}
	for alarmm in ListAlarms()
	return shortestRemaining.
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

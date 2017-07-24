PARAMETER minerFuelQty.
PARAMETER needsOxidizer.

set transferTank to ship:partsdubbed("Transfer Tank").
set fuelStorage to ship:partsdubbed("Fuel Storage").
set minerFuel to ship:partsdubbed("Miner Fuel").
set vesselFuel to ship:partsdubbed("Vessel Fuel").
for tank in minerFuel {
	vesselFuel:add(tank).
	}

print "Take all the resources from the transport ship.".
print " - transfer tank".
set oxidizerTransfer to TRANSFERALL("OXIDIZER", transferTank, fuelStorage).
set oxidizerTransfer:ACTIVE to true.

set fuelTransfer to TRANSFERALL("LIQUIDFUEL", transferTank, fuelStorage).
set fuelTransfer:ACTIVE to false.
set fuelTransfer:ACTIVE to true.

wait until not oxidizerTransfer:ACTIVE.
wait until not fuelTransfer:ACTIVE.

print " - fuel tanks".
set oxidizerTransfer to TRANSFERALL("OXIDIZER", vesselFuel, fuelStorage).
set oxidizerTransfer:ACTIVE to false.
set oxidizerTransfer:ACTIVE to true.

set fuelTransfer to TRANSFERALL("LIQUIDFUEL", vesselFuel, fuelStorage).
set fuelTransfer:ACTIVE to true.

wait until not fuelTransfer:ACTIVE.
wait until not oxidizerTransfer:ACTIVE.


print "".
print "Refuelling transport ship:      ".
print " - " + minerFuelQty + " fuel    ".
set fuelTransfer to TRANSFER("LIQUIDFUEL", fuelStorage, vesselFuel, minerFuelQty).
set fuelTransfer:ACTIVE to true.
wait until not fuelTransfer:ACTIVE.

if needsOxidizer {
	set oxidizerQty to round(minerFuelQty * 1.222, 0).
	print " - " + oxidizerQty + " oxidizer     ".
	set oxidizerTransfer to TRANSFER("OXIDIZER", fuelStorage, vesselFuel, oxidizerQty).
	set oxidizerTransfer:ACTIVE to true.
	wait until not oxidizerTransfer:ACTIVE.
	}

print "Thank you for visiting, have a nice day!".

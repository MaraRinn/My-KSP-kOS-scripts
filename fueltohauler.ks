PARAMETER haulerFuelQty.
PARAMETER needsOxidizer.

set transferTank to ship:partsdubbed("Transfer Tank").
set minerFuel to ship:partsdubbed("Miner Fuel").
set vesselFuel to ship:partsdubbed("Vessel Fuel").
for tank in minerFuel {
	vesselFuel:add(tank).
	}
set fuelStorage to ship:partsdubbed("Fuel Storage").

print "Fill the hauler.".
print " - transfer tank".
set oxidizerTransfer to TRANSFERALL("OXIDIZER", fuelStorage, transferTank).
set oxidizerTransfer:ACTIVE to true.

set fuelTransfer to TRANSFERALL("LIQUIDFUEL", fuelStorage, transferTank).
set fuelTransfer:ACTIVE to true.

wait until not oxidizerTransfer:ACTIVE.
wait until not fuelTransfer:ACTIVE.

print "".
print "Transferring " + haulerFuelQty + " fuel for the hauler.".
set fuelTransfer to TRANSFER("LIQUIDFUEL", fuelStorage, vesselFuel, haulerFuelQty).
set fuelTransfer:ACTIVE to true.
wait until not fuelTransfer:ACTIVE.

if needsOxidizer {
	set oxidizerQty to round(haulerFuelQty * 1.222, 0).
	print "(and " + oxidizerQty + " oxidizer)".
	set oxidizerTransfer to TRANSFER("OXIDIZER", fuelStorage, vesselFuel, oxidizerQty).
	set oxidizerTransfer:ACTIVE to true.
	wait until not oxidizerTransfer:ACTIVE.
	}
print "Thank you for visiting, have a nice day!".

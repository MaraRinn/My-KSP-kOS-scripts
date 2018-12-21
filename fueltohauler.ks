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

set monoStorage to ship:partsdubbed("Monopropellant Storage").
set monoFuel to list().
for part in ship:parts {
	// We're going to fill the parts that aren't tagged for storage
	if part:tag <> "Monopropellant Storage" {
		for resource in part:resources {
			if resource:name = "MONOPROPELLANT" and resource:capacity > 0 {
				monoFuel:add(part).
				}
			}
		}
	}
if monoFuel:length > 0 and monoStorage:length > 0 {
	print " - mono propellant".
	set monoTransfer to TRANSFERALL("MONOPROPELLANT", monoStorage, monoFuel).
	set monoTransfer:ACTIVE to true.
	wait until not monoTransfer:ACTIVE.
	}

print "".
print " - fuel for the hauler".
set fuelTransfer to TRANSFERALL("LIQUIDFUEL", fuelStorage, vesselFuel).
set fuelTransfer:ACTIVE to true.

set oxidizerTransfer to TRANSFERALL("OXIDIZER", fuelStorage, vesselFuel).
set oxidizerTransfer:ACTIVE to true.

wait until not oxidizerTransfer:ACTIVE.
wait until not fuelTransfer:ACTIVE.


print "Thank you for visiting, have a nice day!".

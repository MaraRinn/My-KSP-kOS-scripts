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


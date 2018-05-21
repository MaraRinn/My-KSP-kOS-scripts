// Customisation for 7m Fuel Transport (HS)
print "Initialising 7m Fuel Transport (HS)".

if mass > 500 rcs on.
set minmusTransferFuel to 6800. // Roughly enough fuel to get to Minmus and rendezvous with the station there

function fillup {
	set haulerFuel to 7290.
	runpath("fueltohauler").
	}

function dump {
	set haulerFuel to minmusTransferFuel.
	runpath("fueltostation", haulerFuel, true).
	}

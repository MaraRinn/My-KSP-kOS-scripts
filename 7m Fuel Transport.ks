// Customisation for 7m Fuel Transport
print "Initialising 7m Fuel Transport".
run "orbital_mechanics".

if mass > 500 rcs on.
set minmusTransferFuel to 6800. // Roughly enough fuel to get to Minmus and rendezvous with the station there
set haulerReturnFuel to 6800.
set kerbinParkingOrbit to 300000. // metres!
set minmusParkingOrbit to 50000.

function fillup {
	runpath("fueltohauler").
	}

function dump {
	runpath("fueltostation", haulerReturnFuel, true).
	}

function setKerbinApoapsis {
	if hasNode return.
	set maxAcceleration to ship:availablethrust / ship:mass.
	set semi_major to (SHIP:PERIAPSIS + kerbinParkingOrbit) / 2 + BODY:RADIUS.
	set required_speed_periapsis to sqrt(body:mu * (2/(SHIP:PERIAPSIS + BODY:RADIUS) - 1/semi_major)).
	print "Required: " + required_speed_periapsis.
	set semi_major to (SHIP:APOAPSIS + SHIP:PERIAPSIS) / 2 + BODY:RADIUS.
	set actual_speed_periapsis to sqrt(body:mu * (2/(SHIP:PERIAPSIS + BODY:RADIUS) - 1/semi_major)).
	print "Actual:   " + actual_speed_periapsis.

	set maxDelta to maxAcceleration * 60.
	set requestedDelta to required_speed_periapsis - actual_speed_periapsis.
	set deltaIntent to 0.
	if requestedDelta > maxDelta {
		set deltaIntent to maxDelta.
		}
	else if requestedDelta < -maxDelta {
		set deltaIntent to -maxDelta.
		}
	else {
		set deltaIntent to requestedDelta.
		}

	set myNode to Node(time:seconds + eta:periapsis, 0, 0, deltaIntent).
	add myNode.
	}

function setKerbinPeriapsis {
	if hasNode return.
	create_circularise_node(true).
	}

print "".
print "What am I doing?".

if BODY = Kerbin {
	print " - Orbiting Kerbin".
	if ship:liquidfuel > minmusTransferFuel {
		print " - Have lots of fuel aboard".
		if abs(apoapsis-kerbinParkingOrbit)/apoapsis < 0.01 {
			print " - Approximately in parking orbit".
			if abs(periapsis-kerbinParkingOrbit)/periapsis < 0.01 {
				print " - Time to rendezvous with station".
				set Target to "Kerbin Fuel Station".
				}
			else {
				print " - Finalising parking orbit".
				setKerbinPeriapsis().
				}
			}
		else {
			// Adjust inclination
			// Lower apoapsis to parking orbit
			print " - Performing burns to bring apoapsis to parking orbit".
			setKerbinApoapsis().
			// raise periapsis to parking orbit
			}
		}
	}
else if BODY = Minmus {
	print " - Orbiting Minmus".
	// Fuel tanks empty?
	if ship:liquidfuel < minmusTransferFuel {
		// If Apoapsis is not between 6 and 2000km, raise periapsis above 4.8km and perform capture burn
		
		// If inclination is not close to 0º change inclination at highest AN/DN
		if abs(orbit:inclination) > 0.1 {
			print " - Adjusting inclination to 0".
			AlterInclination(0,true).
			}
		else if apoapsis > minmusParkingOrbit and abs(apoapsis - minmusParkingOrbit) > 1000 {
			// Lower apoapsis to parking orbit
			print " - Lowering apoapsis to parking orbit".
			AlterApoapsis(minmusParkingOrbit).
			}
		else if periapsis < minmusParkingOrbit and abs(periapsis - minmusParkingOrbit) > 1000 {
			// Raise periapsis to parking orbit
			print " - Raising periapsis to parking orbit".
			AlterPeriapsis(minmusParkingOrbit).
			}
		else {
			print " - Time to rendezvous with fuel depot".
			set Target to "Minmus Fuel Depot".
			}
		}
	else { print " - gotta get back to kerbin". }
	
	// Fuel tanks full?
	// Transfer burn to return to Kerbin
	}
else {
	print " - Ummmm…".
	}

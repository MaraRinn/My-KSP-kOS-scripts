// Keep an equatorial relay in sync with Ike

print "Performing station keeping".
set controlPart to ship:partsdubbedpattern("HECS2")[0].
controlPart:controlFrom().

// Where are we, relative to Ike?
set shipVector to -duna:position.
set ikeVector to ike:position - duna:position.
set angle to vang(shipVector, ikeVector).
print "Angle: " + angle.
set shipOrbitNormal to vcrs(ship:orbit:velocity:orbit, shipVector).
set shipTargetNormal to vcrs(shipVector, ikeVector).
set dotp to vdot(shipOrbitNormal, shipTargetNormal).
if dotp < 0 {
	print "Ike is ahead".
	}
else {
	print "Ike is behind".
	}

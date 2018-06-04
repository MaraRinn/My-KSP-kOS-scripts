run "orbital_mechanics".

set done to false.
set rotationDegrees to 0.

// Vectors
lock progradeVector to ship:Prograde:Forevector.
lock positionVector to PositionAt(Body, time:seconds):Normalized * 100.
lock normalVector to VectorCrossProduct(positionVector, progradeVector):normalized * 100.
lock radialVector to VectorCrossProduct(normalVector, progradeVector):normalized * 100.
lock velocityVector to ship:Velocity:Orbit.

// Arrows
set progradeArrow to vecdraw(V(0,0,0), progradeVector:Normalized * 100, red, "prograde", 1, true, 0.2).
set normalArrow to vecdraw(V(0,0,0), normalVector, blue, "normal", 1, true, 0.2).
set radialArrow to vecdraw(V(0,0,0), radialVector, purple, "radial", 1, true, 0.2).
set velocityArrow to vecdraw(V(0,0,0), velocityVector, yellow, "velocity", 1, true, 0.2).
set positionArrow to vecdraw(V(0,0,0), positionVector, green, "position", 1, true, 0.2).
set oppositionArrow to vecdraw(V(0,0,0), -positionVector, cyan, "axis", 1, true, 0.2).

on abort {
	set done to true.
	}

until done {
	set rotatedVelocityVector to RotateVector(progradeVector, rotationDegrees, positionVector:Normalized).
	set velocityArrow:vec to rotatedVelocityVector * 10.
	set rotationDegrees to mod(rotationDegrees + 10, 360).
	wait 1.
	}

clearvecdraws().

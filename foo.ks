run "orbital_mechanics".

if HasTarget {
	set obj to target.
	}
else {
	set obj to ship.
	}

if true {
	set timeToNode to TimeToAscendingNode(obj:orbit).
	set rotationDegrees to 10.
	set positionVector to PositionAt(obj, time:seconds + timeToNode):normalized.
	set velocityVector to VelocityAt(obj, time:seconds + timeToNode):orbit.
	}
else {
	set rotationDegrees to 90.
	set positionVector to list(0,1,0).
	set velocityVector to list(1,0,0).
	}

print "velocity:".
print velocityVector.
print velocityVector:mag.
set P to VectorToQuaternion(velocityVector).
print "P:".
print P.
set R to RotationQuaternion(rotationDegrees, positionVector).
print "R:".
print R.
set I to InverseQuaternion(R).
set T to H(R, P).
set U to H(T,I).
print "U:".
print U.
set vector to QuaternionToVector(U).
print "vector:".
print vector.
print vector:mag.

set progradeVector to velocityVector:normalized.
set normalVector to VectorCrossProduct(velocityVector, positionVector):normalized.
set radialVector to -positionVector:normalized.

set deltaVector to (vector - velocityVector)/2.
print "delta:".
print deltaVector.
print deltaVector:mag.

set burnVector to V( progradeVector * deltaVector, radialVector * deltaVector, normalVector * deltaVector ).
print "burn:".
print burnVector.
print burnVector:mag.

set done to false.
lock progradeVector to ship:Prograde:Forevector:Normalized * 100.
lock positionVector to PositionAt(Minmus, time:seconds):Normalized * 100.
lock normalVector to VectorCrossProduct(positionVector, progradeVector):normalized * 100.
lock radialVector to VectorCrossProduct(normalVector, progradeVector):normalized * 100.
set velocityVector to ship:Velocity:Orbit.
set progradeArrow to vecdraw(V(0,0,0), progradeVector, red, "prograde", 1, true, 0.2).
set normalArrow to vecdraw(V(0,0,0), normalVector, blue, "normal", 1, true, 0.2).
set radialArrow to vecdraw(V(0,0,0), radialVector, purple, "radial", 1, true, 0.2).
set velocityArrow to vecdraw(V(0,0,0), velocityVector, yellow, "velocity", 1, true, 0.2).
set positionArrow to vecdraw(V(0,0,0), positionVector, green, "position", 1, true, 0.2).

on abort {
	set done to true.
	}

until done {
	set P to VectorToQuaternion(velocityVector).
	set R to RotationQuaternion(rotationDegrees, positionVector:normalized).
	set T to H(R, P).
	set U to H(T, I).
	set velocityVector to QuaternionToVector(U).
	set velocityArrow:vec to velocityVector.
	wait 1.
	}

clearvecdraws().

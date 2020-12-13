// Attempt to rendezvous with the selected target.
// Rendezvous mathematics and suggestions: http://forum.kerbalspaceprogram.com/index.php?/topic/122685-how-to-calculate-a-rendezvous/
// Orbit: https://ksp-kos.github.io/KOS_DOC/structures/orbits/orbit.html?highlight=orbit

parameter Destination is target.

runoncepath("lib/utility.ks").

set done to False.
clearscreen.
until not hasnode {
	if hasnode { remove nextnode. }
	}

set radToDeg to (360 / (2 * constant:pi)).

print "Rendezvous Calculations                 " at (0,0).
print "=======================                 " at (0,1).

print " Ship SMA:      " at (0,3).
print " Target SMA:    " at (0,4).
print " Transfer SMA:  " at (0,5).
print " Transfer Time: " at (0,6).
print " Target w:      " at (0,7).
print " Target theta:  " at (0,8).
print " Transfer angle:" at (0,9).
print " Ship angle:    " at (0,10).
print " Target angle:  " at (0,11).
print " delta angle:   " at (0,12).
print " Phasing rate:  " at (0,13).
print " Phasing time:  " at (0,14).
print " Node radius:   " at (0,15).
print " Transfer V:    " at (0,16).

// This is all wrong. Orbits are never circular

// Transfer period
set SmaS to ship:orbit:semimajoraxis.
set SmaT to Destination:orbit:semimajoraxis.
set SmaH to (SmaS + SmaT) / 2.
set transferPeriod to constant:pi * 2 * (SmaH^3/body:mu)^0.5.
set transferTime to transferPeriod / 2.

// Phasing
set transferAngle to 180 - (transferTime / Destination:orbit:period * 360).
set wT to (body:mu / SmaT^3)^0.5 * radToDeg. // °/s
set wS to (body:mu / SmaS^3)^0.5 * radToDeg. // °/s
set theta to transferTime * wT.
set phaseRate to wT - wS.
set shipMeanAnomaly to (ship:orbit:MeanAnomalyAtEpoch + (time:seconds - ship:orbit:epoch) * wS).
set shipAngle to mod(ship:orbit:LongitudeOfAscendingNode + ship:orbit:ArgumentOfPeriapsis + ship:orbit:trueanomaly, 360).
set targetAngle to mod(Destination:orbit:LongitudeOfAscendingNode + Destination:orbit:ArgumentOfPeriapsis + Destination:orbit:trueanomaly, 360).
set currentAngle to targetAngle - shipAngle.
set deltaAngle to transferAngle - currentAngle.
set phaseTime to (deltaAngle / phaseRate).
if phaseTime < 0 { set phaseTime to phaseTime + orbit:period. }
set nodeTime to time:seconds + phaseTime.
set arriveTime to time:seconds + phaseTime + transferTime.
set nodeRadius to (PositionAt(ship, nodeTime) - ship:body:position):mag.
set arrivalRadius to (Positionat(target, arriveTime) - ship:body:position):mag.
set transferV to sqrt(body:mu * (2/nodeRadius - 1/SmaH)).
set transferDeltaV to transferV - VelocityAt(ship, nodeTime):orbit:mag.

set hohmannPeriod to constant:pi * ((ship:orbit:semimajoraxis + Destination:orbit:semimajoraxis)^3 / 8*body:mu)^0.5.

print round(ship:orbit:semimajoraxis, 2) + "          " at (16,3).
print round(Destination:orbit:semimajoraxis, 2) + "               " at (16,4).
print round(SmaH, 2) + "      "        at (16,5).
print round(transferTime, 2) + "        "           at (16,6).
print wT + "                      "                 at (16,7).
print round(theta,2) + "                        "            at (16,8).
print round(transferAngle,2) + "                   "            at (16,9).
print round(shipAngle,2) + "       "                at (16,10).
print round(targetAngle,2) + "      "               at (16,11).
print round(deltaAngle,2) +  "       "              at (16,12).
print round(phaseRate,2) + "      "                 at (16,13).
print round(phaseTime,2) + "      "                 at (16,14).
print round(nodeRadius,2) + "      "                at (16,15).
print round(transferV,2) + "      "                 at (16,16).

if hasnode remove nextnode.
set transferNode to node(TIME:SECONDS + phaseTime, 0, 0, transferDeltaV).
add transferNode.

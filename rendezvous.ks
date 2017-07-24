// Attempt to rendezvous with the selected target.
// Rendezvous mathematics and suggestions: http://forum.kerbalspaceprogram.com/index.php?/topic/122685-how-to-calculate-a-rendezvous/
// Orbit: https://ksp-kos.github.io/KOS_DOC/structures/orbits/orbit.html?highlight=orbit

set done to False.
clearscreen.

set radToDeg to (360 / 2 / constant:pi).

print "Rendezvous Calculations                 " at (0,0).
print "=======================                 " at (0,1).

print " Ship SMA:      " at (0,3).
print " Target SMA:    " at (0,4).
print " Transfer SMA:  " at (0,5).
print " Transfer Time: " at (0,6).
print " Target w:      " at (0,7).
print " Target theta:  " at (0,8).
print " Phase angle:   " at (0,9).
print " Ship a:        " at (0,10).
print " Target a:      " at (0,11).
print " Current angle: " at (0,12).
print " Phasing rate:  " at (0,13).
print " Phasing time:  " at (0,14).
print " Transfer V:    " at (0,15).

// This is all wrong
// law of periods: T^2 / a ^ 3 = k
set SmaS to ship:orbit:semimajoraxis.
set SmaT to target:orbit:semimajoraxis.
set k to ship:orbit:period^2 / SmaS^3.
set transferSemiMajor to (SmaS + SmaT) / 2.
set transferPeriod to (k * transferSemiMajor^3)^0.5. // T = sqrt(k * a^3))
set transferTime to transferPeriod / 2.
set wT to (body:mu / SmaT^3)^0.5 * radToDeg. // °/s
set wS to (body:mu / SmaS^3)^0.5 * radToDeg. // °/s
set theta to transferTime * wT.
set phaseAngle to constant:pi * (1 - ((1 + SmaS/SmaT)^0.3 / 8)^0.5) * radToDeg.
set phaseRate to wT - wS.
set shipAngle to ship:orbit:LongitudeOfAscendingNode + ship:orbit:trueanomaly.
set targetAngle to target:orbit:LongitudeOfAscendingNode + target:orbit:trueanomaly.
set deltaAngle to targetAngle - shipAngle.
set phaseTime to deltaAngle / phaseRate.
set transferV to sqrt(body:mu * (2/SmaS - 1/transferSemiMajor)).
set transferDeltaV to transferV - ship:velocity:orbit:mag.

set hohmannPeriod to constant:pi * ((ship:orbit:semimajoraxis + target:orbit:semimajoraxis)^3 / 8*body:mu)^0.5. // why does this produce weird numbers: they're too big and they change with time?

print round(ship:orbit:semimajoraxis, 2) + "          " at (16,3).
print round(target:orbit:semimajoraxis, 2) + "               " at (16,4).
print round(transferSemiMajor, 2) + "      "        at (16,5).
print round(transferTime, 2) + "        "           at (16,6).
print wT + "                      "                 at (16,7).
print theta + "                        "            at (16,8).
print phaseAngle + "                   "            at (16,9).
print round(shipAngle,2) + "       "                at (16,10).
print round(targetAngle,2) + "      "               at (16,11).
print round(deltaAngle,2) +  "       "              at (16,12).
print round(phaseRate,2) + "      "                 at (16,13).
print round(phaseTime,2) + "      "                 at (16,14).
print round(transferV,2) + "      "                 at (16,15).

if hasnode remove nextnode.
set transferNode to node(TIME:SECONDS + phaseTime, 0, 0, transferDeltaV).
add transferNode.

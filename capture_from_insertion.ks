runoncepath("orbital_mechanics").

set kspSoiLimit to body:soiradius * 0.90 - body:radius.
print "Apoapsis: " + kspSoiLimit.

AlterApoapsis(kspSoiLimit).

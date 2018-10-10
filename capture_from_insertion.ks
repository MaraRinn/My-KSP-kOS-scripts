run orbital_mechanics.

set kspSoiLimit to body:soiradius * 0.95 - body:radius.
print "Apoapsis: " + kspSoiLimit.

AlterApoapsis(kspSoiLimit).

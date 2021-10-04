run "lib/orbital_mechanics".

set STEERINGMANAGER:MAXSTOPPINGTIME to 3.

if Status = "ORBITING" {
	if Body = Minmus and not HasNode {
		if orbit:apoapsis < 0 {
			run "capture_from_insertion".
			}
		}
	}

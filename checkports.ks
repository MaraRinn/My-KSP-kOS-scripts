// Determine which port is facing "forwards" based on the direction the engines are facing.

set dockingPorts to ship:partsTitledPattern("docking port").
list engines in shipEngines.
for myEngine in shipEngines {
	print "Engine " + myEngine + ":".
	for myPort in dockingPorts {
		set dotProduct to myPort:Facing:Vector * myEngine:Facing:Vector.
		if (round(dotProduct,0) = 1 and myPort:State = "Ready"){
			print "   Port " + myPort + " is facing forwards and is not in use".
			myPort:ControlFrom().
			}
		}
	}

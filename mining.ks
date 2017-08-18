clearscreen.
print "MINING OPERATION" at (0,0).
print "================" at (0,1).

set fuelFull to false.
set sunArrow to vecDraw(V(0,0,0), sun:position:normalized * 40, RGB(1,1,0), "Kerbol", 1, true, 0.2).
set sunArrow:vecupdater to { return sun:position:normalized * 40. }.
deploydrills on.
panels on.
radiators on.
fuelcells on.
set miningStarted to time:seconds.

LIST RESOURCES IN RESLIST.
FOR RES IN RESLIST {
	if RES:NAME = "ElectricCharge" {
		set electric to RES.
		}
	if RES:NAME = "Ore" {
		set ore to RES.
		}
	if RES:NAME = "LiquidFuel" {
		set fuel to RES.
		}
	}

ON AG2 {
	preserve.
	set fuelFull to true.
	}

until fuelFull {
	set charge to electric:amount.
	set capacity to electric:capacity.
	set chargePercent to round(100*charge/capacity).
	print "Charge: " + round(charge) + " (" + chargePercent + "%)  " at (0,4).

	set orePercent to round(100*ore:amount/ore:capacity).
	print "Ore:    " + round(ore:amount) + " (" + orePercent + "%)  " at (0,5).

	set fuelPercent to round(100*fuel:amount/fuel:capacity).
	print "Fuel:   " + round(fuel:amount) + " (" + fuelPercent + "%)  " at (0,6).
	if fuelPercent = 100 and orePercent = 100 {
		set fuelFull to true.
		}

	if chargePercent < 40 or ore:amount = ore:capacity {
		drills off.
		}
	if chargePercent > 40 and orePercent < 50 {
		drills on.
		}
	if chargePercent <= 85 or orePercent = 0 {
		isru off.
		}
	if chargePercent > 85 and orePercent > 0 {
		isru on.
		}
	if ore:amount < ore:capacity and fuelPercent = 100 and chargePercent > 40 {
		drills on.
		}

	if drills {
		print "DRILLS ON " at (25,5).
		}
	else {
		print "DRILLS OFF" at (25,5).
		}

	if isru {
		print "ISRU ON " at (25,6).
		}
	else {
		print "ISRU OFF" at (25,6).
		}
	
	wait 3.
	}

print "COMPLETED.  " at (0,0).
set miningFinished to time:seconds.
set duration to round(miningFinished - miningStarted,0).
print "Operation took " + duration + "s." at (0,8).
deploydrills off.
fuelcells off.
set sunArrow to 0.
CLEARVECDRAWS().
set warp to 0.

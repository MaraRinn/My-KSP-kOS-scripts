LIST RESOURCES IN RESLIST.
set hasCharge to false.
set hasOre to false.
set hasFuel to false.
set hasOxidizer to false.

FOR RES IN RESLIST {
	if RES:NAME = "ElectricCharge" {
		set charge to RES.
		lock chargePercent to round(100 * charge:amount / charge:capacity).
		set hasCharge to true.
		}
	if RES:NAME = "Ore" {
		set ore to RES.
		lock orePercent to round(100 * ore:amount / ore:capacity).
		set hasOre to true.
		}
	if RES:NAME = "LiquidFuel" {
		set fuel to RES.
		lock fuelPercent to round(100 * fuel:amount / fuel:capacity).
		set hasFuel to true.
		}
	if RES:NAME = "Oxidizer" {
		set oxidizer to RES.
		lock oxidizerPercent to round(100 * oxidizer:amount / oxidizer:capacity).
		set hasOxidizer to true.
		}
	}

function NextAlarmIsMine {
	set shortestRemaining to 0.
	for alarm in Addons:KAC:Alarms {
		if shortestRemaining = 0 or shortestRemaining > alarm:remaining {
			set shortestRemaining to alarm:remaining.
			set soonestAlarm to alarm.
			}
		}
	return shortestRemaining.
	}
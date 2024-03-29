runoncepath("lib/utility.ks").

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

function elementWithName {
	parameter name.

	list elements in elementList.
	set iter to elementList:iterator.
	
	until not iter:next {
		if iter:value:name:contains(name) {
			return iter:value.
			}
		}
	return "No element with name " + name + " found.".
	}

function fuelToStation {
	PARAMETER elementName.
	PARAMETER vesselFuelQty.
	PARAMETER needsOxidizer.

	set tanker to elementWithName(elementName).
 
	set shipTransferTanks to ship:partsdubbed("Transfer Tank").
	set fuelStorage to ship:partsdubbed("Fuel Storage").
	set minerFuel to ship:partsdubbed("Miner Fuel").
	set shipVesselFuels to ship:partsdubbed("Vessel Fuel").
	for tank in minerFuel {
		shipVesselFuels:add(tank).
		}

	set transferTank to List().
	for tank in shipTransferTanks {
		if tanker:parts:contains(tank) {
			transferTank:add(tank).
			}
		}
	set vesselFuel to List().
	for tank in shipVesselFuels {
		if tanker:parts:contains(tank) {
			vesselFuel:add(tank).
			}
		}

	// Find our Monopropellant.
	set monoStorage to ship:partsdubbed("Monopropellant Storage").
	set monoFuel to list().
	for part in ship:parts {
		// We're going to take all the monopropellant from everywhere
		if part:tag <> "Monopropellant Storage" {
			for resource in part:resources {
				if resource:name = "MONOPROPELLANT" and resource:capacity > 0 {
					monoFuel:add(part).
					}
				}
			}
		}

	print "Take all the resources from the transport ship.".
	print " - transfer tank".
	set oxidizerTransfer to TRANSFERALL("OXIDIZER", transferTank, fuelStorage).
	set oxidizerTransfer:ACTIVE to true.

	set fuelTransfer to TRANSFERALL("LIQUIDFUEL", transferTank, fuelStorage).
	set fuelTransfer:ACTIVE to true.

	wait until not oxidizerTransfer:ACTIVE.
	wait until not fuelTransfer:ACTIVE.

	print " - fuel tanks".
	set oxidizerTransfer to TRANSFERALL("OXIDIZER", vesselFuel, fuelStorage).
	set oxidizerTransfer:ACTIVE to true.

	set fuelTransfer to TRANSFERALL("LIQUIDFUEL", vesselFuel, fuelStorage).
	set fuelTransfer:ACTIVE to true.

	if monoFuel:length > 0 {
		print " - mono propellant".
		set monoTransfer to TRANSFERALL("MONOPROPELLANT", monoFuel, monoStorage).
		set monoTransfer:ACTIVE to true.
		wait until not monoTransfer:ACTIVE.
		}

	wait until not fuelTransfer:ACTIVE.
	wait until not oxidizerTransfer:ACTIVE.


	print "".
	print "Refuelling transport ship:      ".
	print " - " + vesselFuelQty + " fuel    ".
	set fuelTransfer to TRANSFER("LIQUIDFUEL", fuelStorage, vesselFuel, vesselFuelQty).
	set fuelTransfer:ACTIVE to true.
	wait until not fuelTransfer:ACTIVE.

	if needsOxidizer {
		set oxidizerQty to round(vesselFuelQty * 1.222, 0).
		print " - " + oxidizerQty + " oxidizer     ".
		set oxidizerTransfer to TRANSFER("OXIDIZER", fuelStorage, vesselFuel, oxidizerQty).
		set oxidizerTransfer:ACTIVE to true.
		wait until not oxidizerTransfer:ACTIVE.
		}

	print "Thank you for visiting, have a nice day!".
	}

function undock {
	parameter elementName.
	set self to elementWithName(elementName).
	for port in self:DockingPorts {
		port:undock.
		}
	wait 1.
	set kUniverse:ActiveVessel to core:vessel.
	}

function HasAlarm {
	if not addons:available("KAC") {
		return false.
		}
	set alarms to addons:KAC:Alarms.
	return (alarms:length > 0).
	}

// Honour Kerbal Alarm Clock
function KACAlarmWithin {
	parameter seconds.
	if addons:available("KAC") {
		for alarm in addons:KAC:Alarms {
			if alarm:remaining > 0 and alarm:remaining <= seconds { return true. }
			}
		}
	return false.
	}

function NextKACAlarm {
	set alarmList to addons:KAC:Alarms.
	set nextAlarm to alarmList[0].
	for alarm in alarmList {
		if alarm:remaining < nextAlarm:remaining {
			set nextAlarm to alarm.
			}
		}
	return nextAlarm.
	}

function HasShipAlarm {
	if not addons:available("KAC") {
		return false.
		}
	set alarms to ListAlarms("All").
	return (alarms:length > 0).
	}

function NextShipAlarm {
	set alarms to ListAlarms("ALL").
	set nextAlarm to alarms[0].
	for alarm in alarms {
		if alarm:remaining < nextAlarm:remaining {
			set nextAlarm to alarm.
			}
		}
	return nextAlarm.
	}

function NextAlarmIsMine {
	if not HasShipAlarm() {
		return false.
		}
	set soonestKAC to NextKACAlarm().
	set soonestShip to NextShipAlarm().
	return soonestKAC:id = soonestShip:id.
	}

// Warping
function WarpToTime {
	parameter destinationTime.
	set ratesList to kUniverse:timeWarp:RailsRateList.
	until time:seconds >= destinationTime {
		set interval to destinationTime - time:seconds.
		// It takes about 1 real second to speed up or slow down warp.
		from { set i to ratesList:Length - 1. } until (ratesList[i] < (interval)) or (i = 0) step { set i to i - 1.} do { }.
		set kUniverse:timeWarp:Warp to i.
		wait 0.1.
		set warpInterval to ratesList[kUniverse:timeWarp:Warp].
		set waitTime to time:seconds + warpInterval - 1.
		if KACAlarmWithin(warpInterval) {
			print "Waiting for KAC alarm.".
			wait until time:seconds > time:seconds + NextKACAlarm:remaining + 5.
			}
		else {
			wait until time:seconds >= waitTime.
			}
		if kUniverse:ActiveVessel <> ship {
			break.
			}
		}
	set kUniverse:timeWarp:Warp to 0.
	wait until kUniverse:timeWarp:IsSettled.
	}

function WaitForAlarm {
	set soonest to NextKACAlarm().
	print "Waiting for alarm in " + round(soonest:remaining) + " seconds.".
	set warpEndTime to time:seconds + soonest:remaining.
	WarpToTime(warpEndTime).
	if (soonest:type <> "Maneuver") and (soonest:type <> "ManeuverAuto") {
		DeleteAlarm(soonest:id).
		}
	}

function AlignForNode {
	parameter myNode.
	parameter sunwardVector is sun:position.

	set NAVMODE to "Orbit".
	
	if sas and (sasmode = "PROGRADE") {
		lock burnvector to prograde:vector.
		}
	else if sas and (sasmode = "RETROGRADE") {
		lock burnvector to retrograde:vector.
		}
	else if sas and (sasmode = "MANEUVER") {
		lock burnvector to myNode:deltav.
		}
	else {
		sas off.
		lock burnvector to myNode:deltav.
		}
	lock burnIsAligned to (vang(burnvector(), ship:facing:vector) < 0.50) and (ship:angularvel:mag < 0.01) or (burnvector():mag < 0.001).

	if sas {
		unlock steering.
	}
	else {
		set steeringIntent to LookDirUp(burnvector, sunwardVector).
		lock steering to steeringIntent.
		}
	wait until burnIsAligned.
	set returnVector to burnvector.
	unlock steering.
	unlock burnvector.
	return returnVector.
	}

function WaitForNode {
	parameter sunwardVector is sun:position.
	// if the next node is due soon enough, perform it otherwise sit here waiting
	set burnvector to AlignForNode(nextNode, sunwardVector).
	lock acceleration to ship:maxthrust / ship:mass.
	lock burnDuration to burnvector:mag / acceleration.
	lock burnETA to NextNode:eta - (burnDuration/2 + 1).
	set soonest to NextKACAlarm().

	until burnETA <= 800 {
		set warpEndTime to time:seconds + min(soonest:remaining, burnETA).
		print "Next manoeuvre in " + TimeString(burnETA).
		print "Next alarm in " + TimeString(soonest:remaining).
		lock steering to LookDirUp(NextNode:burnvector, SunwardVector).
		WarpToTime(warpEndTime).
		if NextAlarmIsMine() and (soonest:type <> "Maneuver") and (soonest:type <> "ManeuverAuto") {
			DeleteAlarm(soonest:id).
			}
		until NextAlarmIsMine() {
			// FIXME - it would be nice to switch to the vessel that the next alarm applies to
			print " ** Waiting for you to handle next alarm, which is for another vessel **".
			wait 60.
			}
		}

	ExecuteNextNode(sunwardVector).
	}

function WithinError {
	parameter A.
	parameter B.
	parameter relativeErrorAllowed is 0.01.

	set absoluteError to abs(B - A).
	set relativeError to absoluteError / B.
	print "Absolute Error: " + round(absoluteError).
	print "Relative Error: " + round(relativeError,2).
	if (relativeError <= relativeErrorAllowed) {
		return true.
		}
	return false.
	}

function ExecuteNextNode {
	parameter sunwardVector is sun:position.
	set myNode to nextnode.
	set NAVMODE to "Orbit".
	set oldSAS to sas.
	sas off.

	AlignForNode(myNode, sunwardVector).
	lock burnvector to myNode:burnvector.
	lock steering to burnvector.
	lock acceleration to ship:maxthrust / ship:mass.
	lock burnDuration to burnvector():mag / acceleration.
	lock guardTime to time:seconds + myNode:eta - (burnDuration/2 + 1). 
	lock burnIsAligned to (vang(burnvector(), ship:facing:vector) < 0.50) or (burnvector():mag < 0.001).

	// Warp to 10 minute mark to realign.
	set guardTimeETA to guardTime - time:seconds.
	if guardTimeETA > 600 {
		print "Warping to realignment point.".
		set alignTime to guardTime - 600.
		WarpToTime(alignTime).
		wait until burnIsAligned.
		}

	// Warp to the manoeuvre node
	print "Warping to node.".
	WarpToTime(guardTime).
	wait until burnIsAligned.

	print "Performing manoeuvre.".
	wait until time:seconds > guardTime.

	set done to false.
	set desiredThrottle to 0.
	lock throttle to desiredThrottle.
	wait until burnIsAligned.
	until done {
		if burnvector():mag < 0.1 or sas and (sasMode="PROGRADE" or sasMode="RETROGRADE") {
			set done to true.
			set throttleIntent to 0.
			set throttleSetting to 0.
			}
		else {
			set throttleIntent to burnvector():mag/acceleration.
			set throttleSetting to min(throttleIntent, 1).
			set desiredThrottle to throttleSetting.
			}
		print "Throttle Intent: " + round(throttleIntent,2) + "    " at (0,14).
		print "Throttle: " + round(throttleSetting,2) + "    " at (0,15).
		}

	print "Manoeuvre completed.".
	set desiredThrottle to 0.
	SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.
	unlock steering.
	unlock throttle.
	unlock burnIsAligned.
	unlock guardTime.
	unlock burnDuration.
	unlock acceleration.
	unlock burnvector.
	set sas to oldSAS.
	remove nextnode.
	}

function ModulesMatching {
	parameter comparator.
	set modulesOfInterest to List().
	for part in ship:parts {
		for idx in range(0, part:modules:length) {
			set module to part:GetModuleByIndex(idx).
			if comparator(module) {
				modulesOfInterest:add(module).
				}
			}
		}
	return modulesOfInterest.
	}

// Survey costs from https://wiki.kerbalspaceprogram.com/wiki/M700_Survey_Scanner#Electricity_and_time_required
set antenna to Lexicon().
// Value is [ energy per Mit, energy per second ]
antenna:add("Communotron 16", List(6, 20)).
antenna:add("Communotron 16-S", List(6, 20)).
antenna:add("Communotron DTS-M1", List(6, 34.3)).
antenna:add("Communotron HG-55", List(6.67, 133.3)).
antenna:add("Communotron 88-88", List(10, 200)).
antenna:add("HG-5 High Gain Antenna", List(9, 51)).
antenna:add("RA-2 Relay Antenna", List( 24, 68.6)).
antenna:add("RA-15 Relay Antenna", List( 12, 68.6)).
antenna:add("RA-100 Relay Antenna", List( 6, 68.6)).

function MitsFromSurvey {
	declare parameter surveyBody is orbit:body.
	set roughMits to surveyBody:radius * 0.00021.
	return roughMits.
	}

function PowerRequiredForSurvey {
	declare parameter antennaName.
	declare parameter surveyBody is orbit:body.

	set mitsRequired to MitsFromSurvey(surveyBody).
	set energyRequired to mitsRequired * antenna[antennaName][0].
	return energyRequired.
	}

function TimeRequiredForSurvey {
	declare parameter antennaName.
	declare parameter surveyBody is orbit:body.

	set mitsRequired to MitsFromSurvey(surveyBody).
	set mitsRate to antenna[antennaName][1] / antenna[antennaName][0].
	set timeRequired to mitsRequired / mitsRate.
	return timeRequired.
	}

function ModuleHasEnergyFlow {
	parameter thisMod.
	return thisMod:HasField("energy flow").
	}

function CanSurvey {
	declare parameter antennaName.
	declare parameter surveyBody is orbit:body.

	// look for power sources
	set energyFlowModules to modulesMatching(ModuleHasEnergyFlow@).
	set totalEnergyFlow to 0.
	for module in energyFlowModules {
		set moduleEnergyFlow to module:GetField("energy flow").
		set totalEnergyFlow to totalEnergyFlow + moduleEnergyFlow.
		}

	set surveyEnergy to PowerRequiredForSurvey(antennaName).
	set surveyTime to TimeRequiredForSurvey(antennaName).
	set surveyRate to surveyEnergy / surveyTime.
	set unmetEnergyRate to surveyRate - totalEnergyFlow.
	if unmetEnergyRate < 0 set unmetEnergyRate to 0.
	set unmetEnergyAmount to unmetEnergyRate * surveyTime.
	set surveyPossible to (unmetEnergyAmount < charge:amount).
	return surveyPossible.
	}

function TerrainHeight {
	parameter bodyOfInterest is Body.
	if bodyOfInterest = minmus {
		return 5800.
		}
	else if bodyOfInterest = ike {
		return 12800.
		}
	else if bodyOfInterest = mun {
		return 7100.
		}
	else if bodyOfInterest = kerbin {
		return 5000.
		}
	return 0.
	}

function MinimumSafePeriapsis {
	parameter bodyOfInterest is Body.
	return max(bodyOfInterest:ATM:Height, TerrainHeight(bodyOfInterest)).
}

function ActiveEngines {
	set ActiveEnginesList to List().
	list Engines in EngineList.
	for Engine in EngineList {
		if Engine:HasSuffix("Ignition") and Engine:Ignition {
			ActiveEnginesList:Add(Engine).
			}
		}
	return ActiveEnginesList.
	}

function LimitThrust {
	parameter ThrustLimit is 1.
	local ThrustLimiterSettings to Lexicon().
	if ThrottleIntent < 0.01 {
		set ThrottleIntent to ThrottleIntent * 100.
		list Engines in MyEngines.
		for ThisEngine in MyEngines {
			if ThisEngine:HasModule("ModuleEnginesFX") {
				local EngineModule to ThisEngine:GetModule("ModuleEnginesFX").
				set ThrustLimiterSettings[EngineModule] to EngineModule:GetField("Thrust Limiter").
				EngineModule:SetField("Thrust Limiter", ThrustLimit).
				}
			else {
				print "No thrust limiter on " + ThisEngine.
				}
			}
		}
	return ThrustLimiterSettings.
	}

function ResetThrust {
	parameter ThrustLimiterSettings.
	if ThrustLimiterSettings:Keys:Length > 0 {
		for EngineModule in ThrustLimiterSettings:Keys {
			set OldLimit to ThrustLimiterSettings[EngineModule].
			EngineModule:SetField("Thrust Limiter", OldLimit).
			}
		}
	}

function SimpleProgradeRetrogradeSpeedTweak {
	parameter dvIntentDelegate.

	set deltavIntent to dvIntentDelegate().
	set ThrottleDuration to 10.
	until abs(deltavIntent) < 0.0001 {
		set MaxAcceleration to (MaxThrust / Mass).
		set AccelerationIntent to abs(deltavIntent/10).
		set ThrottleIntent to AccelerationIntent / MaxAcceleration.
		set ThrustLimiterSettings to Lexicon().
		if ThrottleIntent < 0.01 {
			set ThrustLimiterSettings to LimitThrust(1).
			set ThrottleIntent to ThrottleIntent * 100.
			}
		sas on.
		wait 0.1.
		print "delta-v intent: " + round(deltavIntent, 4).
		if deltavIntent > 0 {
			set SASMode to "Prograde".
			}
		else {
			set SASMode to "Retrograde".
			}
		wait 0.1.
		wait until Ship:AngularVel:Mag < 0.002.
		lock Throttle to ThrottleIntent.
		wait ThrottleDuration.
		set ThrottleIntent to 0.
		unlock Throttle.
		ResetThrust(ThrustLimiterSettings).
		set NextdeltavIntent to dvIntentDelegate().
		if (deltavIntent > 0) and (NextdeltavIntent < 0) or
		   (deltavIntent < 0) and (NextdeltavIntent > 0) {
		   set ThrottleDuration to ThrottleDuration/2.
		   }
		set deltavIntent to NextdeltavIntent.
		}

	}

function TweakApoapsis {
	parameter newApoapsis.

	set deltavIntentDelegate to {
		set Radius to Orbit:Body:Position:Mag.
		set NewSMA to (Orbit:Periapsis + newApoapsis)/2 + Orbit:Body:Radius.
		set NewSpeedIntent to velocityAtR(Radius, NewSMA, Orbit:Body:Mu).
		return NewSpeedIntent - Velocity:Orbit:Mag.
		}.
	SimpleProgradeRetrogradeSpeedTweak(deltavIntentDelegate).
	}

function TweakPeriod {
	parameter NewPeriod.

	set NewSMA to SemiMajorAxisFromPeriod(NewPeriod).
	set deltavIntentDelegate to {
		set Radius to Orbit:Body:Position:Mag.
		set NewSpeedIntent to
			SpeedFromSemiMajorAxisRadiusMu( NewSMA, Radius, Orbit:Body:Mu ).
		return NewSpeedIntent - Velocity:Orbit:Mag.
		}.
	SimpleProgradeRetrogradeSpeedTweak(deltavIntentDelegate).
	}

function ParameterDefault {
	parameter SourceLexicon.
	parameter KeyName.
	parameter DefaultValue.

	if not(SourceLexicon:HasKey(KeyName)) { return DefaultValue. }
	return SourceLexicon[KeyName].
	}

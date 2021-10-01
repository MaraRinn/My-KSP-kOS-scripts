runoncepath("lib/utility.ks").
runoncepath("lib/vessel_operations.ks").

clearscreen.
print "MINING OPERATION" at (0,0).
print "================" at (0,1).

set fuelFull to false.
deploydrills on.
panels on.
radiators on.
fuelcells on.

ON Abort {
	set fuelFull to true.
	}

function ManageDrills {
	parameter orePercent.
	parameter chargePercent.

	set drillParts to ship:PartsDubbedPattern("drill").
	set drillCount to drillParts:length.
	if orePercent < 90 {
		set oreRation to drillCount.
		}
	else {
		set oreRation to drillCount - floor(drillCount * orePercent / 100).
		}
	set powerRation to min(floor(drillCount * chargePercent / 96), drillCount).
	if orePercent < 90 and chargePercent > 10 {
		set oreRation to drillCount.
		set powerRation to drillCount.
		}
	set drillDemand to min(oreRation, powerRation).
	

	set index to 0.
	for drill in drillParts {
		set drillModule to drill:GetModule("ModuleResourceHarvester").
		if not drillModule:HasField("Surface Harvester") {
			set animationModule to drill:GetModule("ModuleAnimationGroup").
			animationModule:DoAction("Deploy Drill", true).
			}
		if index < drillDemand {
			drillModule:DoAction("Start Surface Harvester", true).
			}
		else {
			drillModule:DoAction("Stop Surface Harvester", true).
			}
		set index to index + 1.
		}
	return drillDemand.
	}

function StartConverter {
	parameter converter.

	for actionName in converter:AllActionNames {
		if actionName:contains("start") {
			converter:DoAction(actionName, true).
			}
		}
	}

function StopConverter {
	parameter converter.

	for actionName in converter:AllActionNames {
		if actionName:contains("stop") {
			converter:DoAction(actionName, true).
			}
		}
	}

function SetConverterStates {
	parameter converterTable. // Expects Lexicon, key is resource name, value is list of ModuleResourceConverter modules
	parameter resourcesToEnable. // Expects a List of resource names (same nomenclature as the modules)

	set workingLexicon to converterTable:Copy().
	for resource in resourcesToEnable {
		if workingLexicon:HasKey(resource) {
			workingLexicon:Remove(resource).
			}
		}
	set resourcesToDisable to workingLexicon:Keys.
	for resource in resourcesToDisable {
		set converterList to converterTable[resource].
		for converter in converterList {
			StopConverter(converter).
			}
		}
	for resource in resourcesToEnable {
		set converterList to converterTable[resource].
		for converter in converterList {
			StartConverter(converter).
			}
		}
	}

function ManageISRU {
	parameter orePercent.
	parameter chargePercent.
	parameter fuelPercent.
	parameter oxidizerPercent.

	set isruParts to ship:PartsDubbedPattern("ISRU").
	set isruConverters to Lexicon().
	set isruConvertersString to "".
	for isruPart in isruParts {
		set moduleList to isruPart:modules.
		from {set index to 0.} until index = moduleList:length step {set index to index + 1.} do {
			if moduleList[index] = "ModuleResourceConverter" {
				set thisModule to isruPart:GetModuleByIndex(index).
				set thisResource to thisModule:AllFieldNames[0].
				if isruConverters:HasKey(thisResource) {
					isruConverters[thisResource]:add(thisModule).
					}
				else {
					isruConverters:add(thisResource, List(thisModule)).
					}
				}
			}
		}
	if chargePercent < 20 {
		set isruConvertersString to "none".
		isru off.
		}
	else if orePercent > 0 {
		if chargePercent < 50 or orePercent < 5 {
			// lf+ox only
			SetConverterStates(isruConverters, List("lf+ox")).
			set isruConvertersString to "lf+ox".
			}
		else if chargePercent < 75 {
			// lf+ox, liquidfuel and oxidizer
			set converters to List().
			if fuelPercent < 100 {
				converters:Add("liquidfuel").
				}
			if oxidizerPercent < 100 {
				converters:Add("oxidizer").
				}
			SetConverterStates(isruConverters, converters).
			set isruConvertersString to converters:Join(", ").
			}
		else {
			isru on.
			set isruConvertersString to "all".
			}
		}
	return isruConvertersString.
	}

set miningStarted to time:seconds.
set startingFuelLevel to fuel:amount.
set fillTimeEstimate to List().
until fuelFull {	
	print "Charge: " + round(charge:amount) + " (" + chargePercent() + "%)  " at (0,4).
	print "Ore:    " + round(ore:amount) + " (" + orePercent() + "%)  " at (0,5).
	print "Fuel:   " + round(fuel:amount) + " (" + fuelPercent() + "%)  " at (0,6).
	print "Ox:     " + round(oxidizer:amount) + " (" + oxidizerPercent() + "%)  " at (0,7).
	
	if round(fuel:amount) = round(fuel:capacity) and round(ore:amount) = round(ore:capacity) {
		set fuelFull to true.
		}

	set activeDrillCount to ManageDrills(orePercent(), chargePercent()).
	set isruString to ManageISRU(orePercent(), chargePercent(), fuelPercent(), oxidizerPercent()).

	if drills {
		print activeDrillCount + " DRILLS ON    " at (25,5).
		}
	else {
		print "DRILLS OFF    " at (25,5).
		}

	if isru {
		print "ISRU " + isruString + "            " at (25,6).
		}
	else {
		print "ISRU OFF" at (25,6).
		}

	if chargePercent() > 95 {
		fuelcells off.
		}
	else {
		fuelcells on.
		}

	if time:seconds > miningStarted and fuel:amount > startingFuelLevel {
		set fuelRate to (fuel:amount - startingFuelLevel)/(time:seconds - miningStarted).
		print "FUEL RATE:    " + round(fuelRate,2) at (0,9).
		if fuelFull  {
			print "FULL." at (0,10).
			}
		else{
			set thisFillEstimate to round((fuel:capacity - fuel:amount)/fuelRate).
			fillTimeEstimate:add(thisFillEstimate).
			if fillTimeEstimate:length > 20 {
				fillTimeEstimate:remove(0).
				}
			if (fillTimeEstimate:length > 5) {
				set runningSum to 0.
				set fillIterator to fillTimeEstimate:Iterator.
				until not fillIterator:Next {
					set runningSum to runningSum + fillIterator:Value.
					}
				set meanEstimate to runningSum / fillTimeEstimate:length.
				}
			print "TIME TO FILL: " + TimeString(meanEstimate) + "    " at (0,10).
			}
		}
	
	wait 3.
	}

print "COMPLETED.  " at (0,0).
set miningFinished to time:seconds.
set duration to round(miningFinished - miningStarted,0).
print "Operation took " + duration + "s." at (0,8).
deploydrills off.
fuelcells off.
isru off.
set warp to 0.

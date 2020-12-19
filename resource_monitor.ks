runoncepath("lib/vessel_operations.ks"). // resources in RESLIST
runoncepath("lib/utility.ks").

set ReportPeriod to 1.
set OldInventory to Lexicon().
set CurrentInventory to Lexicon().

set RawResourceNames to List(
	"ExoticMinerals",
	"MetallicOre",
	"Minerals",
	"RareMetals",
	"Recyclables",
	"Silicates",
	"Substrate"
	).

set ProcessedResourceNames to List(
	"Chemicals",
	"Metals",
	"Polymers",
	"RefinedExotics",
	"Silicon"
	).

set ManufacturedGoodsNames to List(
	"MaterialKits",
	"SpecializedParts",
	"Machinery"
	).

set ResLex to Lexicon().
for Res in RESLIST {
	set ResLex[Res:Name] to Res.
	}

set ResourcesOfInterest to List().
for ResourceName in RawResourceNames {
	ResourcesOfInterest:Add(ResourceName).
	}
for ResourceName in ProcessedResourceNames {
	ResourcesOfInterest:Add(ResourceName).
	}
for ResourceName in ManufacturedGoodsNames {
	ResourcesOfInterest:Add(ResourceName).
	}

function FixedDecimals {
	parameter Quantity.
	parameter Decimals.

	set RoundedQuantity to round(Quantity, Decimals):ToString.
	set DecimalPosition to RoundedQuantity:Find(".").
	if DecimalPosition < 0 {
		set RoundedQuantity to RoundedQuantity + ".":PadRight(Decimals + 1).
		set RoundedQuantity to RoundedQuantity:Replace(" ", "0").
		}
	else if DecimalPosition > (RoundedQuantity:Length - 3) {
		set RemainingPositions to (RoundedQuantity:Length - DecimalPosition - 1).
		set RoundedQuantity to RoundedQuantity + " ":Padright(RemainingPositions).
		set RoundedQuantity to RoundedQuantity:Replace(" ", "0").
		}
	return RoundedQuantity.
	}

function UpdateInventory {
	set OldInventory to CurrentInventory.
	set CurrentInventory to Lexicon().
	for ResourceName in ResLex:Keys {
		set CurrentInventory[ResourceName] to round(ResLex[ResourceName]:Amount, 3).
		}
	}

function ProduceReport {
	set ResourceReport to List().

	for ResourceName in ResourcesOfInterest {
		set ReportRow to List("", "", "").
		set NewResource to ResLex[ResourceName].
		set CurrentInventory[ResourceName] to round(NewResource:Amount, 3).
		set ReportRow[0] to ResourceName.
		set ReportRow[1] to FixedDecimals(NewResource:Amount, 2).
		if OldInventory:Keys:Length > 0 {
			set OldResourceAmount to OldInventory[ResourceName].
			set ResourceConsumption to NewResource:Amount - OldResourceAmount.
			set ResourceConsumptionRate to ResourceConsumption / ReportPeriod.
			set ReportRow[2] to FixedDecimals(ResourceConsumptionRate, 2).
			}
		else {
			set ReportRow[2] to "  -  ".
			}
		ResourceReport:Add(ReportRow).
		}
	return ResourceReport.
	}

clearscreen.
until false {
	UpdateInventory.
	set ResourceReport to ProduceReport().
	DisplayTable(ResourceReport).
	wait ReportPeriod.
	}

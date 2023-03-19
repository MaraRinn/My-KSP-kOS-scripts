runOncePath("lib/utility").
runOncePath("lib/orbital_mechanics").
runOncePath("lib/vessel_operations").
clearScreen.

local deorbitAngle is 140.
local deorbitAltitude is 30000.
local reentryAttackAngle is 30.
local cruiseSpeed is 170.
local cruiseAltitude is 7000.

// MechJeb autoland: 4 degrees, 170m/s approach, 100m/s touchdown

local knowledge is Lexicon().
local KSCLongitude is -74.5. // near enough

local enginemodules is ModulesMatching(ModuleIsRapier@).
local engines is List().
for enginemodule in enginemodules {
    local thisPart is enginemodule:part.
    if engines:find(thisPart) < 0 {
        engines:add(thisPart).
    }
}

function ModuleIsRapier {
    parameter thisModule.
    if thisModule:Name = "ModuleEnginesFX" {
        return True.
    }
    return False.
}

function ShutdownEngines {
    for enginePart in engines {
        local engineModule is enginePart:getModuleByName("MultiModeEngine").
        engineModule:doAction("shutdown engine", True).
    }
}

local cargomodules is ModulesMatching(ModuleIsCargoBay@).
local cargobays is List().
for cargomodule in cargomodules {
    local thisPart is cargomodule:part.
    if cargobays:find(thisPart) < 0 {
        cargobays:add(thisPart).
    }
}

function ModuleIsCargoBay {
    parameter thisModule.
    if thisModule:Name = "ModuleCargoBay" {
        return True.
    }
    return False.
}

function OpenCargoBay {
    for cargoPart in cargobays {
        if cargoPart:hasModule("ModuleAnimateGeneric") {
            local animationModule is cargoPart:getModule("ModuleAnimateGeneric").
            if animationModule:hasEvent("open") {
                animationModule:doEvent("open").
            }
        }
    }
}

function CloseCargoBay{
    for cargoPart in cargobays {
        if cargoPart:hasModule("ModuleAnimateGeneric") {
            local animationModule is cargoPart:getModule("ModuleAnimateGeneric").
            if animationModule:hasEvent("close") {
                animationModule:doEvent("close").
            }
        }
    }
}


until not hasnode {
    if hasnode { remove nextnode. }
}
unset target.

local deorbitReady is false.
local secondsToDeorbit is 0.
local ShipLongitude is ship:longitude.
local arcdistance is KSCLongitude - ShipLongitude.
if arcdistance < 0 {
    set arcdistance to arcdistance + 360.
}
local degreesPerSecond is 360 / orbit:period.
local bodyRotationPerSecond is 360 / body:rotationPeriod.
local angleToDeorbit is (arcdistance - deorbitAngle).
if angleToDeorbit < 0 { set angleToDeorbit to angleToDeorbit + 360. }
local naiveSecondsToDeorbit to angleToDeorbit / degreesPerSecond.
local bodyRotationAngle to bodyRotationPerSecond * naiveSecondsToDeorbit.
set secondsToDeorbit to (angleToDeorbit + bodyRotationAngle) / degreesPerSecond.
if (ship:orbit:periapsis > (deorbitAltitude + 500) and ship:altitude > 70000) {
    local deorbitBurnTime is time:seconds + secondsToDeorbit.
    local deorbitBurn is AlterPeriapsis(deorbitAltitude, ship:orbit, deorbitBurnTime).
    set deorbitBurn:time to deorbitBurnTime.
    kUniverse:QuickSaveTo(ship:name + " Deorbit Burn").
    wait 0.
    ExecuteNextNode().
}

clearScreen.
print "Reentry Guidance".
sas off.
lock East to vectorCrossProduct(ship:up:vector, ship:north:vector).
lock ReentryAttitude to East * AngleAxis(reentryAttackAngle, ship:north:vector).
lock steering to ReentryAttitude.
set navMode to "SURFACE".

set knowledge to Lexicon().
// FIXME: transition from reentry pitch to powered flight is complicated
// Once airspeed is under ~600, reorient to glide towards KSC.
// Maintain airspeed 250m/s and toggle engines to airbreathing mode
// Transition to cruise altitude & cruise speed
until (altitude < 20000) or (ship:velocity:surface:mag < 800) {
    set knowledge:pilotpitch to round(ship:control:pilotpitch, 2).
    set knowledge:pilotroll to round(ship:control:pilotroll, 2).
    set knowledge:pilotpitchtrim to round(ship:control:pilotpitchtrim, 2).
    set knowledge:pilotthrottle to round(ship:control:pilotmainthrottle, 2).
    set knowledge:pilotneutral to ship:control:pilotneutral.
    set knowledge:controlpitch to round(ship:control:pitch, 2).
    set knowledge:speed to round(ship:velocity:surface:mag).
    DisplayValues(knowledge).
    wait 0.
}
ag1 off. // AG1 switches engine mode between airbreathing (off) and LOX-fed (on).
unlock steering.
unlock throttle.
sas on.
wait 0.1.
set sasMode to "PROGRADE".

// TODO: Figure out how to tell when we're no longer able to maintain reentry attitude
// Then transition from this script to MechJeb autopilot
// Or better yet put the autopilot stuff in here!

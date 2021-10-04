runOncePath("lib/utility").
runOncePath("lib/orbital_mechanics").
runOncePath("lib/vessel_operations").
clearScreen.

local deorbitAngle is 155.
local deorbitAltitude is 30000.
local reentryAttackAngle is 30.

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

local cargomodules is ModulesMatching(ModuleIsCargoBay@).
local cargobays is List().
for cargomodule in cargomodules {
    local thisPart is cargomodule:part.
    if cargobays:find(thisPart) < 0 {
        cargobays:add(thisPart).
    }
}

function ModuleIsRapier {
    parameter thisModule.
    if thisModule:Name = "ModuleEnginesFX" {
        return True.
    }
    return False.
}

function ModuleIsCargoBay {
    parameter thisModule.
    if thisModule:Name = "ModuleCargoBay" {
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

local deorbitReady is false.
local secondsToDeorbit is 0.
until deorbitReady {
    local ShipLongitude is ship:longitude.
    local arcdistance is KSCLongitude - ShipLongitude.
    if arcdistance < 0 {
        set arcdistance to arcdistance + 360.
    }
    local degreesPerSecond is 360 / orbit:period.
    local angleToDeorbit is (arcdistance - deorbitAngle).
    if angleToDeorbit < 0 { set angleToDeorbit to angleToDeorbit + 360. }
    set secondsToDeorbit to angleToDeorbit / degreesPerSecond.

    set knowledge:longitude to round(ShipLongitude, 1).
    set knowledge:arcdistance to round(arcdistance, 1).
    set knowledge:angleToDeorbit to round(angleToDeorbit, 1).
    set knowledge:nodeseconds to round(secondsToDeorbit, 1).
    DisplayValues(knowledge).
    if secondsToDeorbit < 120 { set deorbitReady to True.}
}

CancelWarp().
CloseCargoBay().
local deorbitBurn is AlterPeriapsis(deorbitAltitude).
set deorbitBurn:time to time:seconds + secondsToDeorbit.
ExecuteNextNode().

lock East to vectorCrossProduct(ship:up:vector, ship:north:vector).
lock ReentryAttitude to East * AngleAxis(reentryAttackAngle, ship:north:vector).
lock steering to ReentryAttitude.

wait until altitude < 20000.
ag1.
unlock steering.
unlock throttle.
print "Over to you to land this plane.".
print "Activate ABORT to stow vehicle once landed.".

// TODO: Figure out how to tell when we're no longer able to maintain reentry attitude
// Then transition from this script to MechJeb autopilot
// Or better yet put the autopilot stuff in here!

local finished is False.
on abort {
    set finished to true.
}
wait until finished.
ShutdownEngines.


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
    if ship:orbit:periapsis < 40000 { set deorbitReady to True. }
}

CancelWarp().
CloseCargoBay().
sas off.
if (ship:orbit:periapsis > 40000) {
    local deorbitBurn is AlterPeriapsis(deorbitAltitude).
    set deorbitBurn:time to time:seconds + secondsToDeorbit.
    wait 0.
    ExecuteNextNode().
}

clearScreen.
print "Reentry Guidance".
lock East to vectorCrossProduct(ship:up:vector, ship:north:vector).
lock ReentryAttitude to East * AngleAxis(reentryAttackAngle, ship:north:vector).
lock steering to ReentryAttitude.

set knowledge to Lexicon().
// FIXME: transition from reentry flare to powered flight is complicated
// Once airspeed is under ~600, reorient to glide towards KSC.
// Maintain airspeed >300m/s and toggle engines to airbreathing mode
// Transition to cruise altitude & cruise speed
until altitude < 20000 {
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

// TODO: Figure out how to tell when we're no longer able to maintain reentry attitude
// Then transition from this script to MechJeb autopilot
// Or better yet put the autopilot stuff in here!

lock steering to East.
print "Maintaining level flight at 7000m to the East.".
print "Activate ABORT to cancel kOS control." at (0,0).
local finished is false.
local throttlePID is pidloop(0.5, 0.5, 0.005).
set throttlePID.setpoint to cruiseSpeed.
set throttlePID.maxoutput to 1.
set throttlePID.minoutput to 0.
on abort {
    set finished to true.
}
until finished {
    set knowledge:pilotpitch to round(ship:control:pilotpitch, 2).
    set knowledge:pilotroll to round(ship:control:pilotroll, 2).
    set knowledge:pilotpitchtrim to round(ship:control:pilotpitchtrim, 2).
    set knowledge:pilotthrottle to round(ship:control:pilotmainthrottle, 2).
    set knowledge:pilotneutral to ship:control:pilotneutral.
    set knowledge:controlpitch to round(ship:control:pitch, 2).
    DisplayValues(knowledge).
    set throttleControl to pidloop:update(time:seconds, ship:velocity:surface:mag).
}
unlock steering.
unlock throttle.
print "Over to you to land this plane.".
print "Activate ABORT to stow vehicle once landed." at (0,0).
set finished to false.
on abort {
    set finished to true.
}
until finished {
    set knowledge:pilotpitch to round(ship:control:pilotpitch, 2).
    set knowledge:pilotroll to round(ship:control:pilotroll, 2).
    set knowledge:pilotpitchtrim to round(ship:control:pilotpitchtrim, 2).
    set knowledge:pilotthrottle to round(ship:control:pilotmainthrottle, 2).
    set knowledge:pilotneutral to ship:control:pilotneutral.
    set knowledge:controlpitch to round(ship:control:pitch, 2).
    DisplayValues(knowledge).
}
ShutdownEngines.


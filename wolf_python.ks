runOncePath("lib/vessel_operations").
runOncePath("lib/utility").
runOncePath("lib/orbital_mechanics").

parameter desiredAltitude is 80000.

local Vrot is 120.   // m/s at which to lift nose
local Arot is 6.     // degrees to rotate during take-off
local Aflight is 10. // inclination to maintain during ascent to orbit
local RUNMODE_RUNWAY is "accelerating".
local RUNMODE_ROTATE is "rotating".
local RUNMODE_ATMOSPHERE_TO_ORBIT is "10 degrees to orbit".
local RUNMODE_RAISE_PERIAPSIS is "raise periapsis".
local RUNMODE_RAISE_APOAPSIS is "raise apoapsis".
local RUNMODE_CIRCULARISE is "circularise orbit".
local RUNMODE_COMPLETE is "completed".
local knowledge is Lexicon().

// What speed do we need to be doing right now to get to the intended apoapsis?
lock desiredSMA to (desiredAltitude + ship:orbit:periapsis) / 2 + BODY:RADIUS.
lock shipRadius to ship:altitude + ship:body:radius.
lock desiredSpeed to velocityAtR(shipRadius, desiredSMA, body:mu).
lock extraSpeed to desiredSpeed - ship:velocity:orbit:mag.

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

local tcList is ship:partsDubbedPattern("Transport Computer").
local routeModules is List().
if tcList:length > 0 {
    local transportComputer is tcList[0].
    local transportModule is transportComputer:getModule("WOLF_TransporterModule").
    local passengerModule is transportComputer:getModule("WOLF_CrewTransporterModule").
    routeModules:add(transportModule).
    routeModules:add(passengerModule).
}

function ModulesDoEvent {
    parameter eventName.
    for thisModule in routeModules {
        if thisModule:hasEvent(eventName) {
            thisModule:doEvent(eventName).
        }
    }
}
function StartRoute {
    ModulesDoEvent("connect to origin depot").
}
function EndRoute {
    ModulesDoEvent("connect to destination depot").
}

local minimumAltitude is ship:body:atm:height.
lock East to vectorCrossProduct(ship:up:vector, ship:north:vector).
lock EastFlightPath to East * AngleAxis(Aflight, ship:north:vector).
lock EastRotatePath to East * AngleAxis(Arot, ship:north:vector). // avoid tailstrike
lock FlightPath to East. // KSC Runway 90
lock mySteeringIntent to East.
local throttleIntent is 1.

function ModuleIsRapier {
    parameter thisModule.
    if thisModule:Name = "MultiModeEngine" {
        return True.
    }
    return False.
}

function RapierThrust {
    parameter thisPart.
    local engineMode is thisPart:getModule("MultiModeEngine"):getField("mode").
    if engineMode = "AirBreathing" {
        set activeModule to thisPart:getModuleByIndex(1).
    }
    else {
        set activeModule to thisPart:getModuleByIndex(2).
    }
    local thisThrust is activeModule:getField("thrust").
    return thisThrust.
}

function EngineThrust {
    parameter thisPart.
    local thisThrust is 0.
    if thisPart:hasModule("MultiModeEngine") {
        set thisThrust to RapierThrust(thisPart).
    }
    return thisThrust.
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

function TotalThrust {
    parameter ourEngines.
    local engineThrustTotal is 0.
    for thisEngine in ourEngines {
        set engineThrustTotal to engineThrustTotal + EngineThrust(thisEngine).
    }
    return engineThrustTotal.
}

function maxAccelerationFunc {
    return TotalThrust(engines) / ship:mass.
}
lock maxAcceleration to maxAccelerationFunc().

local previousTime is time:seconds.
local previousSpeed is ship:velocity:orbit:mag.
local surfaceAcceleration is 0.
function CollateKnowledge {
    parameter resetLexicon is false.
    if resetLexicon {
        set knowledge to Lexicon().
    }
    set knowledge:thrust to round(TotalThrust(engines)).
    set knowledge:timeToApoapsis to round(eta:apoapsis).
    set knowledge:apoapsis to round(orbit:apoapsis).
    set knowledge:periapsis to round(orbit:periapsis).
    set knowledge:minimumAltitude to minimumAltitude.
    set knowledge:desiredAltitude to desiredAltitude.
    set knowledge:status to ship:status.
    set knowledge:desiredSpeed to round(desiredSpeed).
    set knowledge:extraSpeed to round(extraSpeed).
    set knowledge:throttleIntent to round(throttleIntent,2).
    set currentSpeed to ship:velocity:orbit:mag.
    set currentTime to time:seconds.
    set surfaceAcceleration to (currentSpeed - previousSpeed)/(currentTime - previousTime).
    set knowledge:acceleration to round(surfaceAcceleration, 2).
    set knowledge:maxacceleration to round(maxAcceleration, 2).
    set knowledge:dragComponent to round(maxacceleration - surfaceAcceleration, 2).
    set previousSpeed to currentSpeed.
    set previousTime to currentTime.
}

// Let's take off
brakes off.
sas off.
CloseCargoBay().
set Ship:Control:PilotMainThrottle to 0.
lock steering to mySteeringIntent.
lock throttle to throttleIntent.
StartRoute().
clearscreen.
if ship:status = "PRELAUNCH" or maxThrust = 0 {
    stage.
}

// On the runway, keep nose level until Vrot
set knowledge:runmode to RUNMODE_RUNWAY.

// At Vrot lift the nose but avoid tail strike
when ship:velocity:surface:mag > Vrot then {
    set knowledge:runmode to RUNMODE_ROTATE.
    lock mySteeringIntent to lookdirup(EastRotatePath, ship:up:vector).
}
when ship:velocity:surface:mag > Vrot and status="FLYING" and ship:altitude > 80 then {
    set knowledge:runmode to RUNMODE_ATMOSPHERE_TO_ORBIT.
    lock mySteeringIntent to lookdirup(EastFlightPath, ship:up:vector).
}

// When airspeed stops increasing, switch to closed engines
when ship:status = "FLYING" and ship:velocity:surface:mag > 1000 and surfaceAcceleration < 2 then {
    stage.   // turn on the aerospikes
    ag1 on.  // switch RAPIERs to closed cycle
}

when ship:status = "FLYING" and ship:velocity:surface:mag > Vrot then {
    gear off.
}

when ship:status = "SUB_ORBITAL" then {
    lock mySteeringIntent to ship:prograde:vector.
    set knowledge:runmode to RUNMODE_RAISE_PERIAPSIS.
    AG2 ON.  // Toggle orbital engines (they'll now be off)
    AG10 ON. // Toggle all engines (orbital engines will now be on)
}

// Push apoapsis to desired altitude
local apoapsisThrottleIntentPID is PIDLOOP(-0.1).
set apoapsisThrottleIntentPID:setpoint to 1. // extra velocity required to reach apoapsis
set apoapsisThrottleIntentPID:minOutput to 0.
set apoapsisThrottleIntentPID:maxOutput to 1.

local TTA is 30.
local TTAthrottlePID is PIDLOOP(0.1).
set TTAthrottlePID:setpoint to TTA.
set TTAthrottlePID:minOutput to 0.
set TTAthrottlePID:maxOutput to 1.

until orbit:periapsis > minimumAltitude {
    CollateKnowledge().
    set apThrottleIntent to apoapsisThrottleIntentPID:update(time:seconds, extraSpeed).
    set TTAthrottleIntent to TTAthrottlePID:update(time:seconds, eta:apoapsis).
    set knowledge:apThrottleIntent to round(apThrottleIntent, 2).
    set knowledge:TTAthrottleintent to round(TTAthrottleIntent, 2).
    set throttleIntent to max(TTAthrottleIntent, apThrottleIntent).
    DisplayValues(knowledge).
    wait 0.
}

set knowledge:runmode to RUNMODE_COMPLETE.
unlock steering.
unlock throttle.
CollateKnowledge(true).
DisplayValues(knowledge).
set ship:control:neutralize to true.
create_circularise_node().
CollateKnowledge().
DisplayValues(knowledge).
sas on.
fuelcells on.
unlock all.

// PS: this guy is insane
// https://www.reddit.com/r/KerbalSpaceProgram/comments/3aezew/im_excited_to_show_my_latest_kos_project_a/csc07qo/
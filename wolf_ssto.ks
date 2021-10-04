runOncePath("lib/vessel_operations").
runOncePath("lib/utility").
runOncePath("lib/orbital_mechanics").

parameter desiredAltitude is 80000.

local RUNMODE_TAKEOFF is "takeoff".
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

local Vrot is 150. // m/s at which to lift nose
local minimumAltitude is ship:body:atm:height.
lock East to vectorCrossProduct(ship:up:vector, ship:north:vector).
lock EastFlightPath to East * AngleAxis(10, ship:north:vector).
lock FlightPath to East. // KSC Runway 90
local st is FlightPath.
local throttleIntent is 1.

function ModuleIsRapier {
    parameter thisModule.
    if thisModule:Name = "ModuleEnginesFX" {
        return True.
    }
    return False.
}

function RapierThrust {
    parameter thisPart.
    local engineMode is thisPart:getModuleByIndex(0):getField("mode").
    if engineMode = "AirBreathing" {
        set activeModule to thisPart:getModuleByIndex(1).
    }
    else {
        set activeModule to thisPart:getModuleByIndex(2).
    }
    local thisThrust is activeModule:getField("thrust").
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

function maxAccelerationFunc {
    if ship:maxthrust > 0 {
        return ship:mass / ship:maxthrust.
    }
    return 0.
}
lock maxAcceleration to maxAccelerationFunc().

function TotalThrust {
    parameter ourEngines.
    local accumulator is 0.
    for thisEngine in ourEngines {
        set accumulator to accumulator + RapierThrust(thisEngine).
    }
    return accumulator.
}

local previousTime is time:seconds.
local previousSpeed is ship:velocity:orbit:mag.
function CollateKnowledge {
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
    set knowledge:acceleration to round((currentSpeed - previousSpeed)/(currentTime - previousTime), 1).
    set previousSpeed to currentSpeed.
    set previousTime to currentTime.
}

// Let's take off
brakes off.
sas off.
CloseCargoBay().
set Ship:Control:PilotMainThrottle to 0.
lock steering to st.
lock throttle to throttleIntent.
if ship:status = "PRELAUNCH" or maxThrust = 0 {
    stage.
}

// On the runway, keep nose level until Vrot
set knowledge:runmode to RUNMODE_TAKEOFF.

// At Vrot ~ 150m/s lift the nose to 10 degrees above horizon
when ship:velocity:surface:mag > Vrot or status="FLYING" then {
    set knowledge:runmode to RUNMODE_ATMOSPHERE_TO_ORBIT.
    lock FlightPath to EastFlightPath.
}

// When airspeed stops increasing, switch to closed engines
when ship:status = "FLYING" and knowledge:acceleration < 2 then {
    ag1 on.
    lock FlightPath to ship:prograde:vector.
    set knowledge:runmode to RUNMODE_RAISE_PERIAPSIS.
}

when ship:status = "FLYING" and ship:velocity:surface:mag > Vrot then {
    gear off.
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
    set st to lookdirup(FlightPath, ship:up:vector).
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
CollateKnowledge().
DisplayValues(knowledge).
set ship:control:neutralize to true.
create_circularise_node().
ExecuteNextNode().
OpenCargoBay().
sas on.

// PS: this guy is insane
// https://www.reddit.com/r/KerbalSpaceProgram/comments/3aezew/im_excited_to_show_my_latest_kos_project_a/csc07qo/
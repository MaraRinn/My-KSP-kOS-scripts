runOncePath("lib/vessel_operations").
runOncePath("lib/utility").
runOncePath("orbital_mechanics").

local RUNMODE_TAKEOFF is "takeoff".
local RUNMODE_ATMOSPHERE_TO_ORBIT is "10 degrees to orbit".
local RUNMODE_RAISE_PERIAPSIS is "raise periapsis".
local RUNMODE_RAISE_APOAPSIS is "raise apoapsis to orbital height".
local RUNMODE_CIRCULARISE is "circularise orbit".


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

local enginemodules is ModulesMatching(ModuleIsRapier@).
local engines is List().
for enginemodule in enginemodules {
    local thisPart is enginemodule:part.
    if engines:find(thisPart) < 0 {
        engines:add(thisPart).
    }
}

local Vrot is 150. // m/s at which to lift nose
local desiredAltitude is 80000.
local desiredApoapsis is desiredAltitude + ship:body:radius.
local minimumPeriapsis is ship:body:atm:height + ship:body:radius.
lock East to vectorCrossProduct(ship:up:vector, ship:north:vector).
lock EastFlightPath to East * AngleAxis(10, ship:north:vector).
set Runway90FlightPath to lookdirup(East, up:vector):vector.

// Let's take off
brakes off.
sas off.
lock FlightPath to Runway90FlightPath.
set st to FlightPath.
lock steering to st.
set Ship:Control:PilotMainThrottle to 1.
if ship:status = "PRELAUNCH" or maxThrust = 0 {
    stage.
}

// On the runway, keep nose level until Vrot
local knowledge is Lexicon().
set knowledge:thrust to 0.
set knowledge:runmode to RUNMODE_TAKEOFF.

// While on runway, leave pitch and roll alone.
// Use rudder to steer the plane down the runway


// At Vrot ~ 150m/s lift the nose to 10 degrees above horizon
when ship:velocity:surface:mag > Vrot or status="FLYING" then {
    set knowledge:runmode to RUNMODE_ATMOSPHERE_TO_ORBIT.
    lock FlightPath to EastFlightPath.
}

// Stick to 10 degrees pitch until airbreathing engine thrust drops too low
// When airspeed stops increasing, switch to closed engines
when ship:status = "FLYING" and knowledge:thrust < 60 then {
    ag1 on.
}

when ship:status = "FLYING" and ship:velocity:surface:mag > Vrot then {
    gear off.
}

// Keep going till apoapsis is out of atmosphere
until apoapsis > minimumPeriapsis {
    set knowledge:thrust to round(RapierThrust(engines[0])).
    set knowledge:timeToApoapsis to round(eta:apoapsis).
    set knowledge:apoapsis to round(apoapsis).
    set knowledge:minimumPeriapsis to minimumPeriapsis.
    set knowledge:status to ship:status.
    set st to lookdirup(FlightPath, ship:up:vector).
    DisplayValues(knowledge).
    wait 0.
}
unlock steering.
unlock throttle.
sas on.
wait 0.
set sasmode to "PROGRADE".
set knowledge:runmode to RUNMODE_RAISE_PERIAPSIS.

// Keep apoapsis 50s away until desired orbit is reached or throttle drops below 30%

// I have no idea what I'm doing. My brilliant idea is to estimate what
// the ship's velocity *should* be at this r if the apoapsis was the
// target altitude.

lock semi_major to (desiredapoapsis + SHIP:PERIAPSIS) / 2 + BODY:RADIUS.
lock desiredSpeed to sqrt(body:mu * (2/r - 1/semi_major)).
lock extraSpeed to desiredSpeed - ship:velocity:orbit:mag.

until False {
    set knowledge:thrust to round(RapierThrust(engines[0])).
    set knowledge:timeToApoapsis to round(eta:apoapsis).
    set knowledge:status to ship:status.
    set knowledge:desiredSpeed to desiredSpeed.
    set knowledge:extraSpeed to extraSpeed.
    DisplayValues(knowledge).
    wait 0.
}
unlock throttle.
wait 0.
set knowledge:runmode to RUNMODE_RAISE_APOAPSIS.
DisplayValues(knowledge).
// Plot circularisation burn
create_circularise_node().
// Release controls
unlock steering.
unlock throttle.
set ship:control:neutralize to true.


// PS: this guy is insane
// https://www.reddit.com/r/KerbalSpaceProgram/comments/3aezew/im_excited_to_show_my_latest_kos_project_a/csc07qo/
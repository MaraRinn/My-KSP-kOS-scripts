runOncePath("lib/vessel_operations").

local Vrot is 150. // m/s at which to lift nose
local Vmin is 100. // minimum speed to maintain control authority

// Let's take off
brakes off.
sas on.
set Ship:Control:PilotMainThrottle to 1.
stage.

// On the runway, keep nose level until Vrot
local knowledge is Lexicon().
set knowledge:desiredHeading to 90.
set knowledge:desiredPitch to 0.
set knowledge:desiredYaw to 0.
set knowledge:desiredRoll to 0.
local controlStick is SHIP:CONTROL.

// controlStick has suffixes pitch, yaw, roll.

// I want to have the nose pointing 10 degrees up from horizon
// My controls are rudder, elevator, airelons
// Thus pulling/pushing stick controls the force applied to pitch
// and the stick is two degrees separated from nose:runOncePath
//   stick -> elevator -> delta-pitch -> pitch
// And from desire we get intent:
//  pitchPID converts error in pitch (desire - actual) to pitchrate desire
//  pitchratePID converts error in pitchrate to elevator desire
//  elevatorPID converts error in elevator to control input
// I use a PID for the control surfaces to allow rate limiting/smoothing

local pitchPID is PIDLOOP().
local pitchratePID is PIDLOOP().
local elevatorPID is PIDLOOP().

// Same for rudder
local yawPID is PIDLOOP().
local yawratePID is PIDLOOP().
local rudderPID is PIDLOOP().

// Same for ailerons
local rollPID is PIDLOOP().
local rollratePID is PIDLOOP().
local aileronPID is PIDLOOP().

// At Vrot ~ 150m/s lift the nose to 10 degrees above horizon
when ship:velocity:surface:mag > Vrot then {
    print "Reached Vrot".
    set knowledge:desiredPitch to 10.
}

// Keep it there until airbreathing engine thrust drops too low

until ship:velocity:surface:mag > 1500 {
    local currentPitch is PitchFromHorizon().
    set knowledge:currentPitch to currentPitch.
    set pitchPID:setpoint to knowledge:desiredPitch.
    local pitchCorrection is pitchPID:update(Time:Seconds, currentPitch).
    local pitchTorqueCorrection is pitchratePID:update(Time:Seconds, pitchCorrection).
    local elevatorInput is elevatorPID:update(time:seconds, pitchTorqueCorrection).
    set knowledge:pitchCorrection to pitchCorrection.
    set knowledge:pitchTorqueCorrection to pitchTorqueCorrection.
    set knowledge:elevatorInput to elevatorInput.
    set controlStick:pitch to elevatorInput.
    DisplayTable(knowledge).
}


// When airspeed stops increasing, switch to closed engines
// Keep going till apoapsis is out of atmosphere
// Keep apoapsis 50s away until desired orbit is reached or throttle drops below 30%
// Plot circularisation burn
// Release controls
set ship:control:neutralize to true.

// PS: this guy is insane
// https://www.reddit.com/r/KerbalSpaceProgram/comments/3aezew/im_excited_to_show_my_latest_kos_project_a/csc07qo/
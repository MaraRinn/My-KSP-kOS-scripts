runoncepath("lib/vessel_operations.ks").

function ToggleGroundTether {
	set PDU to ship:partsdubbedpattern("Power Distribution Unit")[0].
	set TetherModule to PDU:GetModule("USI_InertialDampener").
	if TetherModule:HasEvent("toggle ground tether") {
		TetherModule:DoEvent("toggle ground tether").
		return true.
		}
	return false.
	}

function ManageStatusIndicator {
	set lightpart to ship:partstagged("status indicator")[0].
	set lightmodule to lightpart:GetModule("kOSLightModule").
	set redValue to (1 - chargepercent).
	set greenValue to chargepercent.
	set blueValue to 0.
	lightmodule:setfield("light r", redValue).
	lightmodule:setfield("light g", greenValue).
	lightmodule:setfield("light b", blueValue).
	}

function ManageReactor {
	set PDU to ship:partsdubbedpattern("Power Distribution Unit")[0].
	set ReactorModule to PDU:GetModule("USI_Converter").
	if chargepercent < 0.05 {
		if (ReactorModule:HasEvent("Start Reactor")) {
			ReactorModule:DoEvent("Start Reactor").
			}
		}
	else {
		if (ReactorModule:HasEvent("Stop Reactor")) {
			ReactorModule:DoEvent("Stop Reactor").
			}
		}
	}

function DisplayStatus {
	set StatusReport to Lexicon().
	set StatusReport["charge"] to round(chargepercent * 100, 0).
	DisplayValues(StatusReport).
	}

set runmode to "go".
lock chargepercent to (charge:amount / charge:capacity).

until runmode = "stop" {
	ManageStatusIndicator().
	ManageReactor().
	DisplayStatus().
	wait 2.
	}

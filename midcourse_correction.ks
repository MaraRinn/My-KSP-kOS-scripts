runoncepath("orbital_mechanics.ks").
runoncepath("lib/utility.ks").

parameter OS is 0.   // seconds from now to perform the burn
parameter IETA is eta:apoapsis.
parameter DN is 0.   // change we're making to the Normal component of the burn
parameter DP is 0.   // change we're making to the Prograde component of the burn

function PrepareMidcourseCorrection {
	parameter OffsetSeconds is 0.
	parameter InterceptETA is eta:apoapsis.
	parameter DeltaNormal is 0.
	parameter DeltaPrograde is 0.

	until not HasNode {
		if HasNode {
			remove NextNode.
			wait 0.1.
			}
		}

	set NodeTime to time:seconds + OffsetSeconds.
	set NodeVelocity to VelocityAt(Ship, NodeTime):Orbit.
	set NodePosition to PositionAt(Ship, NodeTime).
	set apTime to time:seconds + InterceptETA.
	set ApoapsisPosition to PositionAt(ship, apTime).
	set ApoapsisBodyPosition to ApoapsisPosition - Kerbin:Position.
	set NodeBodyPosition to Body:Position - NodePosition.
	set MinmusPosition to PositionAt(Minmus, apTime) - NodePosition.
	set OldPlaneNormal to VectorCrossProduct(NodeBodyPosition, NodeVelocity).
	set NewPlaneNormal to VectorCrossProduct(NodeBodyPosition, MinmusPosition).
	set NormalXP to VectorCrossProduct(OldPlaneNormal, NewPlaneNormal).
	set XPAngle to VectorAngle(ApoapsisPosition, NormalXP).
	set Angle to VectorAngle(OldPlaneNormal, NewPlaneNormal).
	if XPAngle > 90 and XPAngle < 270 {
		set Angle to Angle.
		}
	else {
		set Angle to -Angle.
		}
	set NewPrograde to RotateVector(NodeVelocity, Angle, -NodeBodyPosition).
	set deltav to NewPrograde - NodeVelocity.

	AlterPlane(Angle, NodeTime).
	set NextNode:Prograde to NextNode:Prograde + DeltaPrograde.
	set NextNode:Normal to NextNode:Normal + DeltaNormal.

	ClearVecDraws().
	if false {
		print "XP angle: " + XPAngle.
		set VelocityVector to NodeVelocity:Normalized * 100.
		set ApoapsisVector to ApoapsisPosition:Normalized * 100.
		set OldNormalVector to OldPlaneNormal:Normalized * 100.
		set NewNormalVector to NewPlaneNormal:Normalized * 100.
		set MinmusVector to MinmusPosition:Normalized * 100.
		set KerbinArrow to VecDraw(V(0,0,0), Kerbin:Position:Normalized * 100, White,   "Kerbin", 1, true, 0.2, true).
		set VelocityArrow to VecDraw(V(0,0,0), VelocityVector,                 Yellow,  "Prograde", 1, true, 0.2, true).
		set ApoapsisArrow to VecDraw(V(0,0,0), ApoapsisVector,                 Yellow,  "Apoapsis", 1, true, 0.2, true).
		set NormalArrow to VecDraw(V(0,0,0), OldNormalVector,                  Magenta, "Normal", 1, true, 0.2, true).
		set MinmusArrow to VecDraw(V(0,0,0), MinmusVector,                     Cyan,    "Minmus", 1, true, 0.2, true).
		set NewNormalArrow to VecDraw(V(0,0,0), NewNormalVector,               Red,     "New Normal", 1, true, 0.2, true).
		set XPArrow to VecDraw(V(0,0,0), NormalXP:Normalized * 50,             Blue,    "XP", 1, true, 0.2, true).
		wait until false.
		}

	set Result to Lexicon( "HasPatch", false).

	if NextNode:Orbit:HasNextPatch {
		set Result["HasPatch"] to true.
		set TargetOrbit to NextNode:Orbit:NextPatch.
		set Inclination to TargetOrbit:Inclination.
		set AoP to TargetOrbit:ArgumentOfPeriapsis.
		if AoP > 180 { set AoP to AoP - 360. }
		set IsPrograde to (Inclination <= 90 or Inclination >= 270).
		set Result["dv"] to round(NextNode:deltav:mag, 2).
		set Result["Periapsis"] to round(TargetOrbit:Periapsis, 2).
		set Result["Inclination"] to round(Inclination, 0).
		set Result["IsPrograde"] to IsPrograde.
		set Result["AoP"] to round(AoP,4).
		set Result["Radius"] to TargetOrbit:Body:Radius.
		}

	return Result.
	}

function BracketCompass {
	parameter Reading.
	if Reading > 270      { set Reading to 360 - Reading. }
	else if Reading > 90  { set Reading to 180 - Reading. }
	return Reading.
	}

function PeriapsisGoalFunction {
	parameter ResultLex.
	parameter TargetPeriapsis.
	if ResultLex["IsPrograde"] {
		set PeriapsisFunction to ResultLex["Periapsis"] - TargetPeriapsis.
		}
	else {
		set PeriapsisFunction to -ResultLex["Periapsis"] - ResultLex["Radius"].
		}
	return PeriapsisFunction.
	}

function SignChanged {
	parameter a.
	parameter b.
	return (a * b) < 0.
	}

PrepareMidcourseCorrection(OS, IETA, DN, DP).

// Next: alter DN and DP to position the periapsis of the remote body orbit as close as possible to target inclination at minimum safe altitude to maximise Oberth effect.


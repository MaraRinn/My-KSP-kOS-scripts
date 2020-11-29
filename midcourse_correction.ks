runoncepath("orbital_mechanics.ks").
runoncepath("lib/utility.ks").

parameter OS is 0.
parameter IETA is eta:apoapsis.
parameter DN is 0.
parameter DP is 0.

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
	set Angle to VectorAngle(OldPlaneNormal, NewPlaneNormal).
	set NewPrograde to RotateVector(NodeVelocity, Angle, -NodeBodyPosition).
	set deltav to NewPrograde - NodeVelocity.

	ClearVecDraws().
	if false {
		set VelocityVector to NodeVelocity:Normalized * 100.
		set ApoapsisVector to ApoapsisPosition:Normalized * 100.
		set OldNormalVector to OldPlaneNormal:Normalized * 100.
		set NewNormalVector to NewPlaneNormal:Normalized * 100.
		set MinmusVector to MinmusPosition:Normalized * 100.
		set KerbinArrow to VecDraw(V(0,0,0), Kerbin:Position:Normalized * 100, White, "Kerbin", 1, true, 0.2, true).
		//set VelocityArrow to VecDraw(V(0,0,0), VelocityVector, Yellow, "Prograde", 1, true, 0.2, true).
		set ApoapsisArrow to VecDraw(V(0,0,0), ApoapsisVector, Yellow, "Apoapsis", 1, true, 0.2, true).
		set NormalArrow to VecDraw(V(0,0,0), OldNormalVector, Magenta, "Normal", 1, true, 0.2, true).
		set MinmusArrow to VecDraw(V(0,0,0), MinmusVector, Cyan, "Minmus", 1, true, 0.2, true).
		set NewNormalArrow to VecDraw(V(0,0,0), NewNormalVector, Red, "New Normal", 1, true, 0.2, true).
		}

	AlterPlane(Angle, NodeTime).
	set NextNode:Prograde to NextNode:Prograde + DeltaPrograde.
	set NextNode:Normal to NextNode:Normal + DeltaNormal.

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

set TargetPeriapsis to 5900.
set PreviousResult to PrepareMidcourseCorrection(OS, IETA, DN, DP).
clearscreen.
// Adjust Inclination to 0
set PreviousAoP to BracketCompass(PreviousResult["AoP"]).
set PreviousPeriapsis to PreviousResult["Periapsis"].
print "AoP: " + PreviousAoP.
set ddN to 1.
until abs(PreviousAoP) < 0.2 {
	set DN to DN + ddN.
	set NextResult to PrepareMidcourseCorrection(OS, IETA, DN, DP).
	set NextAoP to BracketCompass(NextResult["AoP"]).
	if (SignChanged(NextAoP, PreviousAoP)) {
		set ddN to -ddN/2.
		}
	else if abs(NextAoP) >= abs(PreviousAoP) {
		set ddN to -ddN.
		}
	print "AoP: " + NextAoP.
	print "ddN now " + round(ddN,2).
	set PreviousAoP to NextAoP.
	wait 1.
	}

set ddP to 1.
set PreviousPeriapsisDeviation to PeriapsisGoalFunction(NextResult, TargetPeriapsis).
until abs(PreviousPeriapsisDeviation) < 2 {
	set DP to DP + ddP.
	set NextResult to PrepareMidcourseCorrection(OS, IETA, DN, DP).
	set NextPeriapsisDeviation to PeriapsisGoalFunction(NextResult, TargetPeriapsis).
	if (SignChanged(NextPeriapsisDeviation, PreviousPeriapsisDeviation)) {
		set ddP to -ddP/2.
		}
	else if abs(NextPeriapsisDeviation) >= abs(PreviousPeriapsisDeviation) {
		set ddP to -ddP.
		}
	print "Deviation: " + NextPeriapsisDeviation.
	print "ddP now " + ddP.
	set PreviousPeriapsisDeviation to NextPeriapsisDeviation.
	wait 1.
	}

print "done".

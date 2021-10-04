runoncepath("lib/orbital_mechanics").
runoncepath("lib/vessel_operations.ks").

parameter ExpectedRelayCount is 0.
if exists("1:/config.json") {
	set L to readjson("1:/config.json").
	if L:HasKey("ExpectedRelayCount") {
		set ExpectedRelayCount to L["ExpectedRelayCount"].
		print "Used config value of Expected Relay Count: " + ExpectedRelayCount.
		}
	}

set throttleSetting to 0.
lock throttle to throttleSetting.
lock SunwardVector to sun:position.

// Basic relay station keeping
// 1. circularise to desired altitude
// 2. tweak period to open up angle to nearest neighbour to 360º/number of relays
// 3. adjust period at apoapsis
// 4. adjust apoapsis at periapsis

set DesiredPeriod to 0.
set DesiredAltitude to 0.
set AllowedPeriodDeviation to 10.
set AllowedApoapsisDeviation to 500.

function CalculateDesiredOrbitalParameters {
	parameter myOrbit is orbit.
	parameter myAltitude is altitude.

	set intendedPeriod to myOrbit:body:rotationPeriod.
	set currentPeriod to myOrbit:Period.
	set intendedRatio to round(currentperiod / intendedPeriod, 1).
	set halfPeriod to intendedPeriod / 2.
	set halfRatio to round(currentperiod / halfPeriod, 1).
	set thirdPeriod to intendedPeriod / 3.
	set thirdRatio to round(currentperiod / thirdPeriod, 1).
	if intendedRatio > 0.9 {
		set DesiredPeriod to intendedPeriod.
		}
	else if halfRatio > 0.9 {
		set DesiredPeriod to halfPeriod.
		}
	else if thirdRatio >= 0.9 {
		set DesiredPeriod to thirdPeriod.
		}
	
	set desiredSMA to SemiMajorAxisFromPeriod(DesiredPeriod).
	set DesiredAltitude to desiredSMA - myOrbit:Body:Radius.	
	}

function IsARelayLikeMe {
	parameter OtherThing.
	
	if OtherThing:Body = Ship:Body and
		OtherThing:Orbit:Eccentricity < 1 and
		abs(OtherThing:Orbit:Period - DesiredPeriod) < (Ship:Orbit:Period / 400) and
		abs(OtherThing:Orbit:Apoapsis - DesiredAltitude) < (Ship:Orbit:Apoapsis / 20)
		{
		return true.
		}
	return false.
	}

function ListOtherRelays {
	list targets in ThingsInSpace.
	set OtherObjects to List().
	for ThisThing in ThingsInSpace {
		if IsARelayLikeMe(ThisThing) {
			OtherObjects:Add(ThisThing).
			}
		}
	return OtherObjects.
	}

function OrbitAngleToOtherRelay {
	parameter OtherObject.

	set MyPosition to -Body:Position.
	set OtherPosition to OtherObject:Position - Body:Position.
	set OurAngle to VectorAngle(MyPosition, OtherPosition).
	set OurXP to VectorCrossProduct(MyPosition, OtherPosition).
	return List(OurAngle, OurXP).
	}

function TabulateRelayStatus {
	parameter RelayList.
	set Report to Lexicon().
	for Thing in RelayList {
		set AngleParams to OrbitAngleToOtherRelay(Thing).
		set OrbitAngle to round(AngleParams[0],0).
		set XP to AngleParams[1]:Normalized.
		set NormAngle to VectorAngle(NormalVectorFromOrbit(Ship:Orbit), XP).
		if NormAngle < 90 {
			set AheadBehind to "Ahead".
			}
		else {
			set AheadBehind to "Behind".
			}
		set ReportRow to List(Thing, OrbitAngle, AheadBehind).
		Report:Add(Thing:Name, ReportRow).
		}
	return Report.
	}

set Ship:Control:PilotMainThrottle to 0.
CalculateDesiredOrbitalParameters().

if abs(Orbit:Apoapsis - DesiredAltitude) < AllowedApoapsisDeviation and
   abs(Orbit:Period - DesiredPeriod) < AllowedPeriodDeviation {
	print "Orbit looks okay. Checking constellation spacing.".
	set RelayList to ListOtherRelays().
	set RelayCount to RelayList:Length + 1.
	if RelayCount = 0 or ExpectedRelayCount > RelayCount {
		print "Constellation isn't established yet.".
		set RecalibrateOffset to 10 * Orbit:Period + eta:Apoapsis - 60.
		set AlarmTime to time:seconds + RecalibrateOffset.
		set AlarmTitle to "Check constellation status for " + ship:Name.
		set AlarmDescription to "Is there a relay constellation to maintain?".
		AddAlarm("Raw", AlarmTime, AlarmTitle, AlarmDescription).
		}
	else {
		set Report to TabulateRelayStatus(RelayList).
		set ClosestOther to 0.
		for Thing in Report:Keys {
			if ClosestOther = 0 or Report[Thing][1] < ClosestOther[1] {
				set ClosestOther to Report[Thing].
				}
			}
		set IsAhead to ClosestOther[2] = "Ahead".
		set ClosestAngle to ClosestOther[1].
		set DesiredAngle to 360 / RelayCount.
		print ClosestOther[0]:Name + " is " + ClosestOther[2] + " by " + ClosestAngle.
		print "Desired: " + DesiredAngle.

		if not round(abs(DesiredAngle - ClosestAngle)) = 0 {
			set PeriodForHalfADegreePerOrbitSlower to round(DesiredPeriod + (DesiredPeriod / 720),0).
			set PeriodForHalfADegreePerOrbitFaster to round(DesiredPeriod - (DesiredPeriod / 720),0).
			if IsAhead and abs(PeriodForHalfADegreePerOrbitSlower - Orbit:Period) > 1 {
				print "Need to slow down to " + PeriodForHalfADegreePerOrbitSlower.
				runpath("alter_period.ks", PeriodForHalfADegreePerOrbitSlower).
				}
			else if abs(PeriodForHalfADegreePerOrbitFaster - Orbit:Period) > 1 and not IsAhead {
				print "Need to speed up to " + PeriodForHalfADegreePerOrbitFaster.
				runpath("alter_period.ks", PeriodForHalfADegreePerOrbitFaster).
				}
			else {
				print "Current orbital period will close the gap.".
				}
			set NumberOfOrbits to abs(DesiredAngle - ClosestAngle).
			set RecalibrateOffset to NumberOfOrbits * Orbit:Period + eta:Apoapsis - 60.
			set AlarmTime to time:seconds + RecalibrateOffset.
			set AlarmTitle to "Adjust period for " + ship:Name.
			set AlarmDescription to "Time to tweak this vessel's orbit a bit further".
			AddAlarm("Raw", AlarmTime, AlarmTitle, AlarmDescription).
			}
		else {
			print "Constellation looks to be in order.".
			set PeriodError to abs(DesiredPeriod - Orbit:Period). // seconds per orbit
			set SecondsPerDegree to DesiredPeriod/360.
			set ReconveneOrbits to round(SecondsPerDegree / PeriodError).
			print "Let's check status in " + ReconveneOrbits + " orbits.".
			set ReconveneSeconds to ReconveneOrbits * Orbit:Period.
			print " ... that's " + TimeString(ReconveneSeconds).
			set AlarmTime to time:seconds + ReconveneSeconds.
			set AlarmTitle to "Check constellation status for " + ship:Name.
			set AlarmDescription to "Is there a relay constellation to maintain?".
			AddAlarm("Raw", AlarmTime, AlarmTitle, AlarmDescription).
			}
		}
	}
else {
	print "Desired Altitude: " + DesiredAltitude.
	print "Current Apoapsis: " + Orbit:Apoapsis.
	print "Desired Period:   " + DesiredPeriod.
	print "Current Period:   " + Orbit:Period.
	if abs(Orbit:Apoapsis - DesiredAltitude) >= AllowedApoapsisDeviation {
		// Adjust AP at PE
		if (eta:Periapsis < 120) {
			print "Tweaking Apoapsis.".
			TweakApoapsis(DesiredAltitude).
			print "Done.".
			}
		else {
			print "Setting alarm for apoapsis tweaking.".
			set AlarmTime to time:seconds + eta:Periapsis - 90.
			set AlarmTitle to "Adjust apoapsis for " + ship:Name.
			set AlarmDescription to "Time to tweak this vessel's orbit a bit further".
			AddAlarm("Raw", AlarmTime, AlarmTitle, AlarmDescription).
			}
		}
	else if abs(Orbit:Period - DesiredPeriod) >= AllowedPeriodDeviation {
		if (eta:Apoapsis < 120) {
			print "Tweaking Period.".
			TweakPeriod(DesiredPeriod).
			print "Done.".
			}
		else {
			print "Setting alarm for period tweaking.".
			set AlarmTime to time:seconds + eta:Apoapsis - 90.
			set AlarmTitle to "Adjust period for " + ship:Name.
			set AlarmDescription to "Time to tweak this vessel's orbit a bit further".
			AddAlarm("Raw", AlarmTime, AlarmTitle, AlarmDescription).
			}
		}
	}

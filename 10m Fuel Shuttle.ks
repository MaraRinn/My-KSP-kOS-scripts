print "Initialising 7m Fuel Shuttle".
set STEERINGMANAGER:PITCHPID:KD to 4.
set STEERINGMANAGER:YAWPID:KD to 4.
if mass > 2000 rcs on. // This ship is extremely heavy when full, and doesn't have enough torque.
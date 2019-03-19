print "Booting " + core:tag.
// Wait for world to load
wait until ship:unpacked.
print " - Unpacked".
wait until kUniverse:timeWarp:isSettled.
print " - Settled".
wait 3.
print " - Thumbs twiddled".
switch to 0.
set Ship:Control:PilotMainThrottle to 0.

if core:tag:length > 0 {
	set missionFilePath to "mission/" + core:tag.
	if exists(missionFilePath) {
		runoncepath(missionFilePath).
		}
	}

// Calculate required velocity at apoapsis (or periapsis) for circular orbit

function create_circularise_node {
	declare parameter isApoapsis is true.

	// For circular orbit, µ = rv^2
	// So v = sqrt(µ/r)
	if isApoapsis {
		set r to body:radius + ship:apoapsis.
		}
	else {
		set r to body:radius + ship:periapsis.
		}
	set required_velocity_magnitude to sqrt(body:mu/r).

	// Estimate speed of this ship at APOAPSIS
	// https://gaming.stackexchange.com/questions/144030/how-do-i-calculate-necessary-delta-v-for-circularization-burn

	set semi_major to (SHIP:APOAPSIS + SHIP:PERIAPSIS) / 2 + BODY:RADIUS.
	set orbit_speed to sqrt(body:mu * (2/r - 1/semi_major)).

	// Create manoeuvre node at apoapsis

	set dR to 0.
	set dN to 0.
	set dP to required_velocity_magnitude - orbit_speed.
	if isApoapsis {
		set nodeTime to eta:apoapsis + time:seconds.
		}
	else {
		set nodeTime to eta:periapsis + time:seconds.
		}

	set circularisation to node(nodeTime,dR, dN, dP).
	add circularisation.
}

// From https://www.reddit.com/r/Kos/comments/4y08of/yet_another_change_inclination_script/

parameter new_inclination is 0.

set my_node to CreateManuverNodeToChangeInc(new_inclination).

function SignOnly
{
	parameter value.
	
	if value >= 0 return 1.
	if value < 0 return -1.
}

function CreateManuverNodeToChangeInc 
{
    parameter target_inclination.
    parameter lan_t is ship:Orbit:LAN. // Not implemented.

// Match inclinations with target by planning a burn at the ascending or
// descending node, whichever comes first.

// from https://github.com/xeger/kos-ramp/blob/master/node_inc_equ.ks
// This piece of code reliably finds the next intersection with the equatorial plane -- if ecc = 0.

    local position is ship:position-ship:body:position.
    local velocity is ship:velocity:orbit.
    local ang_vel is 4 * ship:obt:inclination / ship:obt:period.

    local equatorial_position is V(position:x, 0, position:z).
    local angle_to_equator is vang(position,equatorial_position).

    if position:y > 0 {
        if velocity:y > 0 {
            // above & traveling away from equator; need to rise to inc, then fall back to 0
            set angle_to_equator to 2 * ship:obt:inclination - abs(angle_to_equator).
        }
    } else {
        if velocity:y < 0 {
            // below & traveling away from the equator; need to fall to inc, then rise back to 0
            set angle_to_equator to 2 * ship:obt:inclination - abs(angle_to_equator).
        }
    }

    local frac is (angle_to_equator / (4 * ship:obt:inclination)). 
    local dt is frac * ship:obt:period. // Assumes ecc = 0.
    local t is time + dt.

// Perform a binary search to find the /actual/ intersection with the orbital plane to handle orbits with ecc > 0.

    declare local original_node_eta is t.
    declare local Lat_at_Node is 0.
    declare local Lng_At_Node is 0.
    lock Lat_At_Node to Ship:Body:GeoPositionOf(PositionAt(Ship, t)):Lat.
    lock Lng_At_Node to Ship:Body:GeoPositionOf(PositionAt(Ship, t)):Lng. // For troubleshooting
    declare local Last_Lat_At_Node is Lat_At_Node.
    declare local sign is 1.

// Determine which direction we should be moving in to get closer to the node (the previous calculation might
// have overshot, after all).

    set LastT to T.

    set t to t + 0.0001.
    if Last_Lat_At_Node > Lat_At_Node
    {
        set Last_Lat_At_Node to Lat_At_Node.
        set t to t - 0.0002.
        set sign to -1.
    }

// Next, do a fast [jumping ahead by Period / 10, so never more than 5 iterations] search to find two times, one before
// the node that we are looking for, one after.  In the vast majority of cases, the first "hop" will find the right answer.

    declare local increment is Ship:Orbit:Period / 10.
    until SignOnly(Last_Lat_At_Node) <> SignOnly(Lat_At_Node)
    {
        //print "loop".
        set Last_Lat_At_Node to Lat_At_Node.
        set LastT to T.
        set t to t + (sign*increment).
    }

// Now all you have to do is make sure you keep one time with a negative latitude and one time with a positive latitude
// at all times, and we will quickly converge to the desired time (this is a binary search).

    declare iteration_cnt is 0.
    declare local Latitudes is list(Lat_At_Node, Last_Lat_At_Node).
    declare local Time_To_Latitudes is list(T, LastT).

    until (iteration_cnt > 50) or (round(Lat_At_Node, 8) = 0)
    {
        //print "("+round(Latitudes[0], 4)+", "+round(Latitudes[1], 4)+")".
        set iteration_cnt to iteration_cnt + 1.
        set T to (Time_To_Latitudes[0] + Time_To_Latitudes[1]) / 2.
        if Lat_At_Node > 0
        {
            if Latitudes[0] < 0
            {
                set Latitudes[1] to Lat_At_Node.
                set Time_To_Latitudes[1] to T.
            }
            else
            {
                set Latitudes[0] to Lat_At_Node.
                set Time_To_Latitudes[0] to T.
            }
        }
        else
        {
            if Latitudes[0] > 0
            {
                set Latitudes[1] to Lat_At_Node.
                set Time_To_Latitudes[1] to T.
            }
            else
            {
                set Latitudes[0] to Lat_At_Node.
                set Time_To_Latitudes[0] to T.
            }
        }
    }

    print "Longitude at node: "+round(Lng_At_Node, 4).
    print "Latitude at node: "+round(Lat_At_Node, 4).

// Copied, with modifications, from https://www.reddit.com/r/Kos/comments/3r5pbj/set_inclination_from_orbit_script/
// This script, by itself, can't reliably calculate the intersection with the orbital plane, but it does a good job
// at calculating the delta-V required when ecc = 0.

    declare local incl_i is SHIP:OBT:INCLINATION.   // Current inclination
    declare local lan_i is SHIP:OBT:LAN.        // Current longitude of the ascending node.

// setup the vectors to highest latitude; Transform spherical to cubic coordinates.
    declare local Va is V(sin(incl_i)*cos(lan_i+90),sin(incl_i)*sin(lan_i+90),cos(incl_i)).
    declare local Vb is V(sin(target_inclination)*cos(lan_t+90),sin(target_inclination)*sin(lan_t+90),cos(target_inclination)).
// important to use the reverse order
    declare local Vc is VCRS(Vb,Va).

// These are the only variables required if you assume ecc = 0.

    // declare local orbit_at_node is OrbitAt(Ship, T).
    declare local ecc is Ship:Orbit:ECCENTRICITY.
    declare local my_speed is VELOCITYAT(SHIP, T):ORBIT:MAG.
    declare local d_inc is arccos (vdot(Vb,Va) ).
//  declare local d_inc is target_inclination - incl_i. // This doesn't work /at all/ for the formula based calculations.
    declare local dvtgt1 to (2 * (my_speed) * SIN(d_inc/2)). // Assumes ecc = 0

// These variables are required if ecc > 0 (my additions)

    declare local mean_motion is (Constant:Pi*2) / Ship:Orbit:Period. // Must be in radians (see below for proof) -- https://en.wikipedia.org/wiki/Mean_motion
    declare local SemiMajorAxis is Ship:Orbit:SemiMajorAxis.
    declare local ArgOfPeriapsis to Ship:Orbit:ArgumentOfPeriapsis.

// https://en.wikipedia.org/wiki/True_anomaly (My work)
//
// The calculation in https://www.reddit.com/r/Kos/comments/3r5pbj/set_inclination_from_orbit_script/ is incorrect -- 
// I believe the error is that it is using LongitudeOfAscendingNode (LAN) and assuming that Body:RotationAngle = 0.
// This is probably true for Kerbin, but it isn't true for Earth (in RSS)...

    declare local vel_vector is VelocityAt(Ship, T):Orbit. // SOI-RAW
    declare local pos_vector is PositionAt(Ship, T) - Ship:Body:Position. // Ship-RAW -> SOI-RAW, https://ksp-kos.github.io/KOS/math/ref_frame.html
    declare local Ang_Mom_Vector is vcrs(pos_vector, vel_vector). // from Wikipedia
    declare local Ecc_Vector is (vcrs(vel_vector, ang_mom_vector) / Ship:Body:Mu) - (pos_vector / pos_vector:Mag). // Vector that points from Pe to Ap, from Wikipedia
    declare local node_true_anom is arccos( vdot(ecc_vector, pos_vector) / (ecc_vector:mag*pos_vector:mag) ).  // From Wikipedia
    if vdot(pos_vector, vel_vector) < 0
    {
        set node_true_anom to 360 - node_true_anom.
    }

// I've verified that the above code produces the correct result in the following ways:
//    * Ship:Orbit:TrueAnomaly = Node_True_Anom when time to node = 0.
//    * Ship:Orbit:TrueAnomaly = 0 when time to Pe = 0.
// Both are true regardles of the ecc of the orbit.

    print "Node True Anomaly: "+round(node_true_anom, 8).
    print "Ship True Anomaly: "+round(Ship:Orbit:TRUEANOMALY, 8).
    print "".
    print "Arg Of Pe        : "+round(ArgOfPeriapsis, 8).

// https://en.wikipedia.org/wiki/Orbital_inclination_change, should handle ecc <> 0 correctly, but...
//
// This formula doesne't seem to work properly, but I'm not sure why -- node_true_anom is correct (see above),  but 
// examining the formula reveals that the issue almost has to be in this calculation or Argument Of Pe, as follows:
//
//   * This formula simplifies to "(2 * (vel_vector:Mag) * SIN(d_inc/2))" when ecc = 0 (per Wikipedia).
//   * Therefore, the additional terms in the formula that we are using must evalute to "vel_vector:Mag" when ecc = 0.
//        * sqrt(1-sqr(ecc)) = sqrt(1-sqr(0)) = sqrt(1) = 1 -- CHECK.
//        * 1 + ( ecc*cos(node_true_anom) ) = 1 + ( 0 * ...) = 1 -- CHECK.
//    * The following two terms need to simplify to vel_vector:Mag
//          * mean_motion is Pi*2/Period [Which is why mean_motion must be defined in terms of radians, not degrees]
//          * SemiMajorAxis = Radius of orbit (when ecc = 0)
//      * Circumfrance of a circle = 2*Pi*Radius
//      -> Circumfrance/period = vel_vector:Mag (when ecc = 0) -- CHECK.
//    * Leaving "cos(ArgOfPeriapsis + node_true_anom)", which must evaluate to a constant value of 1, which means
//      that ArgOfPeriapsis+node_true_anom must be 0 (or 180, if -1 is OK) when ecc = 0.
//
//      This occurs when Pe and Ap are co-located with AN and DN, as follows:
//      * argument of Pe = "the angle between the AN vector and the Pe vector" = 0 when Pe = AN, 
//      * node_true_anom = "the angle between Pe and a point on the orbit", with the point defined as either AN
//        DN, so if Pe = AN then this value will be 0, and (since ecc=0) DN will be 180 degrees offset, which 
//        is probably OK (cos(180) = -1, but reversing the sign at DN is likely correct behavior).
//
//      However, when ecc=0 /all/ points on the orbit qualify as Pe (and Ap, for that matter), so you could /define/
//      this term to 1 -- but...  lim(ecc->0) cos(ArgOfPe + ANTrueAnom) should be /also/ evaluate to
//      1, but I don't see how it could in all cases -- if, say, ecc is 0.00001, then Pe occurs at a specific 
//      point in the orbit and AN /also/ occurs at a specific point in the orbit, which is determined (in part) by the 
//          orbital plane that you are attempting to adjust to.  But ArgOfPe and ANTrueAnom are related terms (ArgOfPe
//      changes when An changes, and vice versa), so...  Maybe it all works out?
//
//      As a side note:  ArgOfPe + ANTrueAnom = 90 must indicate that you are coplanar already, as cos(90) = 0, 
//      which would force the value of this equation to 0.

    declare local dvtgt2 is 
        ( 
            2*sin(d_inc/2)
            * sqrt(1-(ecc^2))
            * cos(ArgOfPeriapsis + node_true_anom)
            * mean_motion 
            * SemiMajorAxis
        ) / 
        (
            1 +
            ( ecc*cos(node_true_anom) )
        ).

// Try 3 -- a simple rotation...
//
// Many more variables are defined here than are required to complete the calculation -- the extra variables are 
// for troubleshooting.

    // declare local vel_vector is VelocityAt(Ship, T):Orbit. // from above, current velocity vector at node

    declare local desired_delta_incl is (target_inclination - incl_i).
    // declare local desired_delta_incl is d_inc. // This doesn't work /at all/
    declare local rot_dir_angle is desired_delta_incl.
    declare local rot_dir is 0.
    declare local new_vel_vector is 0.
    declare local actual_delta_incl is 0.
    declare local angle_error is 0.

// I'm baffled:  in the below logic, actual_delta_inc should be equal to rot_dir_angle (and, therefore, angle_error = 0).
// It isn't.
//
// However...
//
// If you do a binary search to force VAng to return the correct result (by varying "rot_dir_angle"), the final burn vector 
// tends to approach the value given by the ecc=0 formula (not the ecc>0 formula).  Odder still, burning to this vector
// /increases/ final inclination error (vs. using the inital result of the rotation).
//
// So, the rotation seems to work -- mostly.  Burning to the final velocity vector doesn't /quite/ get you to zero
// inclination, although it far outperforms the ecc = 0 formula when ecc is large.  It also results in large changes to
// Ap and Pe, which shouldn't happen either.  So there is something wrong with the below logic, but I'm not sure what.
//
// Something is subtly wrong with this rotation, though -- the new delta-v vector doesn't /quite/ get you to the desired
// inclination, and Pe / Ap change fairly dramatically after the burn.

    declare local east_pos_vector_2 is 
        V(
            pos_vector:X*cos(0.01),
            pos_vector:Y,
            pos_vector:Z*sin(0.01)
        ).
    declare local north_pos_vector_2 is
        V(
            pos_vector:X,
            pos_vector:Y*cos(0.01),
            pos_vector:Z*sin(0.01)
        ).
    declare local east_vector is (east_pos_vector_2 - pos_vector):Normalized.
    declare local north_vector is (north_pos_vector_2 - pos_vector):Normalized.
    declare local calc_inclination is VAng(vel_vector, east_vector).
    print "Inclination                             : "+round(Ship:Orbit:Inclination, 4).
    print "Angle between east vector and vel_vector: "+round(calc_inclination, 4).
    print "Angle between north vector and vel_vec  : "+round(VAng(vel_vector, north_vector), 4).
    print "Angle between north and east vector      : "+round(VAng(north_vector, east_vector), 4).

    set rot_dir to AngleAxis(rot_dir_angle, pos_vector). // pos_vector = radial out
    set new_vel_vector to rot_dir*vel_vector. // Rotate the velocity vector by the calculated direction

    set actual_delta_incl to VAng(new_vel_vector, vel_vector). // This is expected to be zero, but isn't.
    set angle_error to abs(actual_delta_incl) - abs(desired_delta_incl).

// Trying to calculate the expected inclination of the new orbit (https://en.wikipedia.org/wiki/Orbital_inclination),
// but... it doesn't work (it isn't even /close/).

    declare local PostBurnAng_Mom_Vector is vcrs(pos_vector, new_vel_vector).
    declare local dvtgt3_expected_incl is arccos(PostBurnAng_Mom_Vector:Z / PostBurnAng_Mom_Vector:Mag).

    declare local new_vel_deltav_vector is new_vel_vector - vel_vector.
    declare local dvtgt3 is new_vel_deltav_vector:Mag.

    print "angle_error : "+round(angle_error, 4).
    print "Expected new inclination: "+round(dvtgt3_expected_incl, 8).

    print "Delta-V required using ecc=0 formula : "+round(dvtgt1, 2).
    print "Delta-V required using ecc<>0 formula: "+round(dvtgt2, 2). 
    print "Delta-V required using rotation      : "+round(dvtgt3, 3).

    declare local inc_node1 is node(T:Seconds, 0, 0, 0).
    declare local inc_node2 is node(T:Seconds, 0, 0, 0).
    declare local inc_node3 is node(T:Seconds, 0, 0, 0).

    set inc_node1:Normal to dvtgt1 * cos(d_inc/2).
    set inc_node1:Prograde to -abs(dvtgt1 * sin(d_inc/2)).

    set inc_node2:Normal to dvtgt2 * cos(d_inc/2).
    set inc_node2:Prograde to -abs(dvtgt2 * sin(d_inc/2)).

// Vel_Vector is /not/ the same as the prograde direction!
//
// However, the position and velocity vectors still define the orbital plane (even though they will only be at right angles
// to one another if ecc=0, or ecc<>0 but you are at one of the two points in the orbit where vertical speed = 0), so
// vcrs(position, velocity) still points in the correct direction (90 degrees to /both/ vectors).  Then you can 
// turn around and take vcrs(normal, position) and get the vector that is at right angles to both the position vector
// (= Radial Out) and the normal vector.  This vector is the prograde direction as defined in KSP (the direction the 
// craft would travel if the orbit was ecc = 0).

    declare local RadialOutAtNode is (PositionAt(Ship, T) - Ship:Body:Position):Normalized. // AKA Pos_Vector
    declare local NormalAtNode is vcrs(PositionAt(Ship, T) - Ship:Body:Position, VelocityAt(Ship, T):Orbit):Normalized. // AKA Ang_Mom_Vector
    declare local ProgradeAtNode is vcrs(NormalAtNode, RadialOutAtNode):Normalized. // This is new!

    set inc_node3:Normal to vdot(new_vel_deltav_vector, NormalAtNode).
    set inc_node3:Prograde to vdot(new_vel_deltav_vector, ProgradeAtNode).
    set inc_node3:RadialOut to vdot(new_vel_deltav_vector, RadialOutAtNode).

    if velocityat(ship, T):orbit:y > 0 {
      set inc_node1:Normal to -Inc_Node1:Normal.
      set inc_node2:Normal to -Inc_Node2:Normal.
    }

    add inc_node1.
    declare local inc_node1_Inc_Delta is abs(inc_node1:Orbit:Inclination - target_inclination).
    remove inc_node1.
    add inc_node2.
    declare local inc_node2_Inc_Delta is abs(inc_node2:Orbit:Inclination - target_inclination).
    remove inc_node2.
    add inc_node3.
    declare local inc_node3_inc_Delta is abs(inc_node3:Orbit:Inclination - target_inclination).

// This should be zero, right?  It isn't -- implying that there is an error breaking down the new_vel_deltav_vector
// into its prograde / normal / radial components.
//
// This is another potential source of why the inc_delta for the rotation case is not zero, although it is /so/ low
// in comparison to the magnitude of the error vectors that this seems very, very, unlikely.

    declare local manuver_node_delta is inc_node3:DeltaV - new_vel_deltav_vector.
    print "inc_node_3 errors:".
    print "  X = "+round(manuver_node_delta:X, 4).
    print "  Y = "+round(manuver_node_delta:Y, 4).
    print "  Z = "+round(manuver_node_delta:Z, 4).
    print "Mag = "+round(manuver_node_delta:Mag, 4).
    print "inc_node_3 burn vector:".
    print " Pro = "+round(inc_node3:Prograde, 4).
    print " Nml = "+round(inc_node3:Normal, 4).
    print " Rdl = "+round(inc_node3:RadialOut, 4).
    remove inc_node3.

    declare local inc_node is 0.

    print "Ecc=0 inclination delta is "+round(inc_node1_Inc_Delta, 8).
    print "Ecc<>0 inclination delta is "+round(inc_node2_Inc_Delta, 8).
    print "Rotation inclination delta is "+round(inc_node3_inc_Delta, 8).

    if (inc_node1_Inc_Delta < inc_node2_Inc_Delta) and (inc_node1_inc_delta < inc_node3_inc_delta)
    {
        print "Using ecc=0 calculation".
        set inc_node to inc_node1.
    }
    else
    {
        if inc_node2_inc_delta < inc_node3_inc_delta
        {
            print "Using ecc<>0 calculation".
            set inc_node to inc_node2.
        }
        else
        {
            print "Using rotation calculation".
            set inc_node to inc_node3.
        }
    }

    add inc_node.
    return inc_node.
}
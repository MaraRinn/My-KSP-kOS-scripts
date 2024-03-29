FUNCTION deltaVstage
{   
    // fuel name list
    LOCAL fuels IS list().
    fuels:ADD("LiquidFuel").
    fuels:ADD("Oxidizer").
    fuels:ADD("SolidFuel").
    fuels:ADD("MonoPropellant").

    // fuel density list (order must match name list)
    LOCAL fuelsDensity IS list().
    fuelsDensity:ADD(0.005).
    fuelsDensity:ADD(0.005).
    fuelsDensity:ADD(0.0075).
    fuelsDensity:ADD(0.004).

    // initialize fuel mass sums
    LOCAL fuelMass IS 0.

    // calculate total fuel mass
    FOR r IN STAGE:RESOURCES
    {
        LOCAL iter is 0.
        FOR f in fuels
        {
            IF f = r:NAME
            {
                SET fuelMass TO fuelMass + fuelsDensity[iter]*r:AMOUNT.
            }.
            SET iter TO iter+1.
        }.
    }.  

    // thrust weighted average isp
    LOCAL thrustTotal IS 0.
    LOCAL mDotTotal IS 0.
    LIST ENGINES IN engList. 
    FOR eng in engList
    {
        IF eng:IGNITION
        {
            LOCAL t IS eng:maxthrust*eng:thrustlimit/100. // if multi-engine with different thrust limiters
            SET thrustTotal TO thrustTotal + t.
            IF eng:ISP = 0 SET mDotTotal TO 1. // shouldn't be possible, but ensure avoiding divide by 0
            ELSE SET mDotTotal TO mDotTotal + t / eng:ISP.
        }.
    }.
    LOCAL avgIsp is 0.
    IF mDotTotal = 0 set avgIsp to 0.
    ELSE set avgIsp to thrustTotal/mDotTotal.

    // deltaV calculation as Isp*g0*ln(m0/m1).
    LOCAL deltaV IS avgIsp*9.81*ln(SHIP:MASS / (SHIP:MASS-fuelMass)).

    RETURN deltaV.
}

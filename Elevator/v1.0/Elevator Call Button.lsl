key ElevatorKey = "55cbac23-e23e-497a-9fe1-fab35000aa69";
default
{
    state_entry()
    {
        llSay(0, "Floor 1 Call Button Ready");
        llListen(420, "", NULL_KEY, "");
    }

    touch_start(integer total_number)
    {
        llRegionSayTo(ElevatorKey, 604, "1");
        llSetPrimitiveParams([
            PRIM_COLOR, ALL_SIDES, <255,255,0>, 1.0,
            PRIM_POINT_LIGHT, TRUE, <128,128,0>, 1.0, 0.7, 0.0,
            PRIM_GLOW, ALL_SIDES, 0.10,
            PRIM_FULLBRIGHT, ALL_SIDES, TRUE]);
    }
    
    listen(integer channel, string sender, key sendid, string msg){
        if(msg=="OFF"){
            llSetPrimitiveParams([
            PRIM_COLOR, ALL_SIDES, <255,255,255>, 1.0,
            PRIM_POINT_LIGHT, FALSE, <128,128,0>, 1.0, 0.7, 0.0,
            PRIM_GLOW, ALL_SIDES, 0.0,
            PRIM_FULLBRIGHT, ALL_SIDES, FALSE]);
        }
    }
    
    
}
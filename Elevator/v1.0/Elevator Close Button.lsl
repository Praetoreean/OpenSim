default
{
    state_entry()
    {
        llSay(0, "Close Button Ready");
    }

    touch_start(integer total_number)
    {
        llSay(420, "99C");
        llSetPrimitiveParams([
            PRIM_COLOR, ALL_SIDES, <255,255,0>, 1.0,
            PRIM_POINT_LIGHT, TRUE, <128,128,0>, 1.0, 0.7, 0.0,
            PRIM_GLOW, ALL_SIDES, 0.10,
            PRIM_FULLBRIGHT, ALL_SIDES, TRUE]);
    }
    
    link_message(integer sender, integer num, string msg, key id){
        if(msg=="OFF"){
            llSetPrimitiveParams([
            PRIM_COLOR, ALL_SIDES, <255,255,255>, 1.0,
            PRIM_POINT_LIGHT, FALSE, <128,128,0>, 1.0, 0.7, 0.0,
            PRIM_GLOW, ALL_SIDES, 0.0,
            PRIM_FULLBRIGHT, ALL_SIDES, FALSE]);
        }
    }
    
    
}
default
{
    state_entry()
    {
        llSetColor(<0.0,1.0,0.0>, 4);
    }
    
    touch(integer num){
        llSay(0, "Loading Main Category...");
        llSetColor(<0.0,1.0,0.0>, 4);
        llMessageLinked(LINK_ALL_OTHERS, 0, "nogreen", llDetectedKey(0));
        llMessageLinked(LINK_ROOT, 0, "MAIN", llDetectedKey(0));
    }
    
    link_message(integer send_num, integer num, string msg, key id){
        if(msg=="nogreen"){
            llSetColor(<1.0,1.0,1.0>, 4);
        }
    }
}
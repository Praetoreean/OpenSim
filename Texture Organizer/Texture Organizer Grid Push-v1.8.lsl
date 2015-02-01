default
{
    on_rez(integer parms){
        llResetScript();
    }
    
    state_entry()
    {
        
    }
    touch(integer num){
        llMessageLinked(LINK_ROOT, llGetLinkNumber(), "gridpush", llDetectedKey(0));
    }
}
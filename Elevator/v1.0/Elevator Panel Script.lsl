

default
{
    state_entry()
    {
        llListen(421, "", NULL_KEY, "");
    }
    
    on_rez(integer params){
        llResetScript();
    }
    
    listen(integer chan, string sender, key id, string message){
        llOwnerSay("Engine Saw Car Reach Floor: "+message);
    }
}
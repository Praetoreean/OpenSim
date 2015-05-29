integer DChannel = 420;
string mode = "closed";
float MoveDistance = 0.9;
float MoveBack;
list Floors = ["1O","2O","3O","4O","5O","6O","7O","8O","9O","10O","11O","12O","13O","14O","15O","16O","99O"];


default
{
    state_entry()
    {
        llListen(DChannel, "", "", "");
    }
    
    listen(integer channel, string name, key id, string message){
        if(llListFindList(Floors, [message])!= -1 && mode == "closed"){
            mode = "open";
            vector Pos = llGetLocalPos();
            Pos.x = Pos.x - MoveDistance;
            llSleep(3.0);
            llSetPos(Pos);
            llSetTimerEvent(5.0);
            llMessageLinked(LINK_SET, 0, "OFF", NULL_KEY);
        }else if(message=="99C" && mode == "open"){
            llSetTimerEvent(3.0);
        }else{
            llMessageLinked(LINK_SET, 0, "OFF", NULL_KEY);
        }
    }
    
    timer(){
        vector Pos = llGetLocalPos();
        Pos.x = Pos.x + MoveDistance;
        llSetPos(Pos);
        mode = "closed";
        llSetTimerEvent(0);
    }
}
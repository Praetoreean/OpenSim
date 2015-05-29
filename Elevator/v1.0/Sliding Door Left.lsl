integer DChannel = 420;
string mode;
float MoveDistance = 1.0;
float MoveBack;

default
{
    state_entry()
    {
        llListen(DChannel, "", "", "");
    }
    
    listen(integer channel, string name, key id, string message){
        if(message=="1O" || message=="99O"){
            if(mode=="open"){
                return;
            }
            mode = "open";
            //vector Pos = llGetPos();
            //Pos.y = Pos.y + MoveDistance;
            //llSetPos(Pos);
             llSetKeyframedMotion(
                    [<0.0,MoveDistance,0.0>, 3],
                [KFM_DATA, KFM_TRANSLATION, KFM_MODE, KFM_FORWARD]);
            llSetTimerEvent(5.0);
        }
    }
    
    timer(){
        MoveBack = MoveDistance * -1;
        llSetKeyframedMotion(
                    [<0.0,MoveBack,0.0>, 3],
                [KFM_DATA, KFM_TRANSLATION, KFM_MODE, KFM_FORWARD]);
        mode = "closed";
        llSetTimerEvent(0);
    }
}
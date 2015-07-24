// Elevator Door Script (For External Doors)
/*
    Receives Open or Close Command on Channel specified by DChannel
    Direction of Movment is changed by altering flag Side
*/

integer DChannel = 421; // Com Channel for Open/Close Messages
integer DChannelHandle;
integer Floor = 1;
string mode; // Mode Flag (Open/Closed)
float MoveDistance = 0.95; // Mode Distance (approx door width)
float MoveBack; // Hold MoveDistance * -1 when needed
float ReturnTimer = 10.0; // Time to Wait before auto closing the door.
integer SideToggle = TRUE; // Left/Right
string Axis = "x"; // The Axis of Movement (x,y,z)
integer DebugMode = TRUE; // Debug Mode
vector ClosedPos = ZERO_VECTOR;

DebugMessage(string msg){
    if(DebugMode){
        llOwnerSay(msg);
    }
}

default
{
    state_entry()
    {
        llListenRemove(DChannelHandle);
        llSleep(0.5);
        DChannelHandle = llListen(DChannel, "", "", "");
        if(!SideToggle){
            MoveDistance = MoveDistance * -1;
        }
        ClosedPos = llGetPos();
        DebugMessage("Move Distance: "+(string)llRound(MoveDistance)+"\nClosed Pos: "+(string)ClosedPos+"\nCom Channel: "+(string)DChannel+"\nAxis: "+Axis+"\nFloor: "+(string)Floor+"\nReturn Timer: "+(string)llRound(ReturnTimer)+" seconds");
    }
    
    listen(integer channel, string name, key id, string message){
        if(channel==DChannel){
            list InputData = llParseString2List(message, ["||"], []);
            string CMD = llList2String(InputData, 0);
            string FLOOR = llList2String(InputData, 1);
            if((integer)FLOOR==Floor){
                if(CMD=="Open"){
                    if(mode=="open"){
                        return;
                    }
                    mode = "open";
                    //vector Pos = llGetPos();
                    //Pos.y = Pos.y + MoveDistance;
                    //llSetPos(Pos);
                    if(Axis=="y"){
                        llSetKeyframedMotion(
                            [<0.0,MoveDistance,0.0>, 3],
                            [KFM_DATA, KFM_TRANSLATION, KFM_MODE, KFM_FORWARD]
                        );
                    }else if(Axis=="x"){
                        llSetKeyframedMotion(
                            [<MoveDistance,0.0,0.0>, 3],
                            [KFM_DATA, KFM_TRANSLATION, KFM_MODE, KFM_FORWARD]
                        );
                    }
                    llSetTimerEvent(ReturnTimer);
                }else if(CMD=="Close"){
                    if(mode=="closed"){
                        llSetKeyframedMotion([],[KFM_COMMAND, KFM_CMD_STOP]);
                        llSetTimerEvent(0);
                        llSetPos(ClosedPos);
                        return;
                    }
                    MoveBack = MoveDistance * -1;
                    if(Axis=="x"){
                        llSetKeyframedMotion(
                                [<MoveBack,0.0,0.0>, 3],
                                [KFM_DATA, KFM_TRANSLATION, KFM_MODE, KFM_FORWARD]
                        );
                    }else if(Axis=="y"){
                        llSetKeyframedMotion(
                                [<0.0,MoveBack,0.0>, 3],
                                [KFM_DATA, KFM_TRANSLATION, KFM_MODE, KFM_FORWARD]
                        );
                    }
                    mode = "closed";
                    llSetTimerEvent(0);
                }
            }
        }
    }
    
    timer(){
        MoveBack = MoveDistance * -1;
        if(Axis=="y"){
            llSetKeyframedMotion(
                    [<0.0,MoveBack,0.0>, 3],
                    [KFM_DATA, KFM_TRANSLATION, KFM_MODE, KFM_FORWARD]
            );
        }else if(Axis=="x"){
            llSetKeyframedMotion(
                    [<MoveBack,0.0,0.0>, 3],
                    [KFM_DATA, KFM_TRANSLATION, KFM_MODE, KFM_FORWARD]
            );
        }
        mode = "closed";
        llSetTimerEvent(0);
    }
}
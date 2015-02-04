// Avatar Scanner Engine v1.0
// Created by Tech Guy (Zachary Williams) 2015
/* 
*   This Script Listens for Calls for any JackPot Servers, who provide a list of Avatar Ids to check for
*   and return a list on the same channel, but speaking only to the primitive from which the call came.
*
*/

// Configuration

    // Constants
        integer ComChannel = -18006;
        integer DBComChannel = -260046;
        string EMPTY = "";
        string SecurityKey = "3d7b1a28-f547-4d10-8924-7a2b771739f4";
        key GameEventDBServer = "dbfa0843-7f7f-4ced-83f6-33223ae57639";
        string HoverTextString = "Avatar Scanner";
            // Incoming Field Ids
                integer SECKEY = 0;
                integer CMD = 1;
    // Variables
        list FoundUsers = [];
    // Switches
        integer DebugMode = TRUE;
    // Handles
        integer ComHandle;
// Custom Functions
Initialize(){
    llListenRemove(ComHandle);
    llSleep(0.1);
    ComHandle = llListen(ComChannel, EMPTY, EMPTY, EMPTY);
    llOwnerSay("Scanner Online!");
}

// Check key if any incoming request and validate against Security Key
integer SecurityCheck(key CheckID){
    if(CheckID!=SecurityKey){
        return FALSE;
    }else{
        return TRUE;
    }
}

integer ScanForUser(string userid){
    if(DebugMode){
        llOwnerSay("Scanner Received UserID String: "+userid);
    }
    llSensor("", userid, AGENT, 64.0, PI);
    return FALSE;
}


// Main Program
default{
    on_rez(integer params){
        llResetScript();
    }
    
    state_entry(){
        // Bring Scanner Online
        Initialize();
    }
    
    sensor (integer num_detected)
    {
        FoundUsers = FoundUsers + (string)llDetectedKey(0);
        if(DebugMode){
            llOwnerSay("Found User: "+llDetectedKey(0));
        }
    }
 
    no_sensor()
    {
        
    }
    
    listen(integer chan, string cmd, key id, string data){
        if(DebugMode){
            llOwnerSay("Listen Event Fired:\nCommand: "+cmd+"\n"+"Data: "+data);
        }
        if(SecurityCheck(llList2Key(llParseString2List(data, "||", []), 0))==FALSE){ // If Device did not Send Security Key
            if(DebugMode){
                llOwnerSay("Un-Authorized Accept Attempt of "+HoverTextString+"!\rEvent Logged!");
            }
            list SendList = [] + [SecurityKey] + ["INSERT"] + ["Un-Authd Access to User DB"] + ["Un-Authorized Access attempt made to "+HoverTextString+"."] + [data];
            string SendString = llDumpList2String(SendList, "||");
            llRegionSayTo(GameEventDBServer, DBComChannel, SendString);
            return;
        }
        if(chan==ComChannel ){
            cmd = llList2String(llParseStringKeepNulls(data, ["||"], []), CMD);
            if(DebugMode){
                llOwnerSay("CMD: "+cmd);
            }
            if(cmd=="SCANFOR"){
                list UserIDS = llList2List(llParseStringKeepNulls(data, ["||"], []), 2, -1);
                integer i;
                for(i=0;i<llGetListLength(UserIDS);i++){
                    if(llList2String(UserIDS, i)!="UPPOT"){
                        ScanForUser(llList2String(UserIDS, i));
                    }
                }
                llRegionSayTo(id, ComChannel, llDumpList2String(FoundUsers, "||"));
                if(DebugMode){
                    llOwnerSay("Response Sent!\rTEST"+llDumpList2String(FoundUsers, "||"));
                }
            }
        }
    }
}
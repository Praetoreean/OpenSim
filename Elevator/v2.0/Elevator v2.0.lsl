    // Key Framed Elevator v2.0
// Created by Tech Guy of IO 2015
/*

    This elevator uses llSetKeyframedMotion() to facilitate smooth uniform motion.

*/

// Created by Tech Guy of IO

// Configuration Directives
/* This Section Contains Configuration Variables that will contain data set by reading the notecard specified by ConfigFile Variable */
        
    // Communication Channels
    integer MenuComChannel; // Menu Communications Channel for All User Dialog Communications
    integer ComChannel; // General Communication Channel for Inter-Device Communication
    integer DoorChannel = 420;

// System Variables
/* This Section contains variables that will be used throughout the program. */
    // Admin ACL
        list Admins = []; // List of Administrator Keys Read in from ConfigFile
    // Communication Handles
        integer MenuComHandle; // Menu Communications Handle
        integer ComHandle; // General Communications Handle
    // Config Card Reading Variables
        integer cLine; // Holds Configuration Line Index for Loading Config Loop
        key cQueryID; // Holds Current Configuration File Line during Loading Loop
    // Configuration Variables
        list Floors = [ 1 ];
        list Seats = [];
        integer CurrentFloor = 1;
        list DestFloor = []; // Holds List of Floors that have called it or it has been order to go to. In Order of Selection
        integer OpMode = FALSE; // Elevator is in Non-Operational Mode
        string RunMode = "Offline"; // Ready/MoveUp/MoveDown/Offline
        float SpeedT; // Travel Speed (Multipled by Travel Distance to get Key Framed Animation Time)
        float DiM; // Distance in Meters from current Floor to Next Floor in DestFloor List.
        float SitTimeOut;
        string TimerMode = "";
        vector destPos;
        vector nextfloor;
        float travelTime;
        integer dest_floor;
        integer OutCallButtonChannel;
        list ButtonLinks = [];
        list ButtonNames = [];
        
        
        
        
// System Constants
/* This Section contains constants used throughout the program */
string BootMessage = "Booting..."; // Default/Initial Boot Message
string ConfigFile = ".config"; // Name of Configuration File
string EMPTY = "";

// Color Vectors
list colorsVectors = [<0.000, 0.455, 0.851>, <0.498, 0.859, 1.000>, <0.224, 0.800, 0.800>, <0.239, 0.600, 0.439>, <0.180, 0.800, 0.251>, <0.004, 1.000, 0.439>, <1.000, 0.522, 0.106>, <1.000, 0.255, 0.212>, <0.522, 0.078, 0.294>, <0.941, 0.071, 0.745>, <0.694, 0.051, 0.788>, <1.000, 1.000, 1.000>];

// List of Names for Colors
list colors = ["BLUE", "AQUA", "TEAL", "OLIVE", "GREEN", "LIME", "ORANGE", "RED", "MAROON", "FUCHSIA", "PURPLE", "WHITE"];  

// System Switches
/* This Section contains variables representing switches (integer(binary) yes/no) or modes (string "modename" */
    // Debug Mode Swtich
        integer DebugMode = FALSE; // Is Debug Mode Enabled before Reading Obtaining Configuation Information

// Imported Functions
/* This section contains any functions that were not written by Tech Guy */

// Home-Brew Functions
/* This section contains any functions that were written by Tech Guy */

// Debug Message Function
DebugMessage(string msg){
    if(DebugMode){
        llOwnerSay(msg);
    }
}

// Send Any User a Message
SendMessage(string msg, key userid){
    if(userid=="NULL_KEY" || userid==""){
        //llSay(0, msg);
        llRegionSay(0, msg);
    }else if(msg!="" && userid!=NULL_KEY){
        //llInstantMessage(userid, msg);
        llRegionSayTo(userid, 0, msg);
    }else{
        DebugMessage("Error Sending User Message: "+msg);
    }
}

// Main Initialization Logic, Executed Once Upon Script Start    
Initialize(){
    SendMessage(BootMessage, llGetOwner()); // State Booting Message
    MenuComChannel = (integer)(llFrand(-1000000000.0) - 1000000000.0); // Randomize Dialog Com Channel
    SendMessage("Configuring...", llGetOwner()); // Message Owner that we are starting the Configure Loop
    cQueryID = llGetNotecardLine(ConfigFile, cLine); // Start the Read from Config Notecard
}

// System has started Function (Runs After Configuration is Loaded, as a result of EOF)
SystemStart(){
    Display("01");
    ResetButtons();
    SendMessage("System Started!", llGetOwner());
}

// Add Admin (Add provided Legacy Name to Admins List after extrapolating userKey)
AddAdmin(string LegacyName){
    string FName = llList2String(llParseString2List(LegacyName, [" "], []), 0);
    string LName = llList2String(llParseString2List(LegacyName, [" "], []), 1);
    DebugMessage("First Name: "+FName+" Last Name: "+LName);
    key UserKey = osAvatarName2Key(FName, LName);
    if(UserKey!=NULL_KEY){
        Admins = Admins + UserKey;
        DebugMessage("Added Admin: "+LegacyName);
    }else{
        DebugMessage("Unable to Resolve: "+LegacyName);
    }
}


//  Configuration Directives Processor (Called Each Time a Line is Found in the config File)
LoadConfig(string data){
    if(data!=""){ // If Line is not Empty
        //  if the line does not begin with a comment
        if(llSubStringIndex(data, "#") != 0)
        {
        //  find first equal sign
            integer i = llSubStringIndex(data, "=");
 
        //  if line contains equal sign
            if(i != -1){
                //  get name of name/value pair
                string name = llGetSubString(data, 0, i - 1);
                //  get value of name/value pair
                string value = llGetSubString(data, i + 1, -1);
                //  trim name
                list temp = llParseString2List(name, [" "], []);
                name = llDumpList2String(temp, " ");
                //  make name lowercase
                name = llToLower(name);
                //  trim value
                temp = llParseString2List(value, [" "], []);
                value = llDumpList2String(temp, " ");
                //  Check Key/Value Pairs and Set Switches and Lists
                if(name=="debugmode"){ // Check DeBug Mode
                    if(value=="TRUE" || value=="true"){
                        DebugMode = TRUE;
                        llOwnerSay("Debug Mode: Enabled!");
                    }else if(value=="FALSE" || value=="false"){
                        DebugMode = FALSE;
                        llOwnerSay("Debug Mode: Disabled!");
                    }
                }else if(name=="comchannel"){
                    ComChannel = (integer)value;
                    DebugMessage("Opening Com Channel ("+(string)ComChannel+")...");
                    ComHandle = llListen(ComChannel, EMPTY, EMPTY, EMPTY);
                    if(ComHandle>0){
                        DebugMessage("Com Channel Open!");
                    }else{
                        DebugMessage("Unable to Open Com Channel ("+(string)ComChannel+")!");
                    }
                }
        }else{ //  line does not contain equal sign
                SendMessage("Configuration could not be read on line " + (string)cLine, NULL_KEY);
            }
        }
    }
}

// Scan LinkSet for Prims marked seat and add their link id to seats list
ScanForSeats(){
    integer NumLinks = llGetNumberOfPrims();
    integer i;
    for(i=1;i<NumLinks;i++){
        //DebugMessage("Checking Prim "+(string)i+" for seat...");
        string Name = llGetLinkName(i);
        if(Name=="seat"){
            Seats = Seats + [ i ];
            DebugMessage("Found Seat "+(string)llGetListLength(Seats)+" Link ID: "+llList2String(Seats, -1)+". Setting Sit Target...");
            llLinkSitTarget(llList2Integer(Seats, -1),<0.0,0.0,1.0>, ZERO_ROTATION);
        }
    }
    SystemStart();
    
}

// Reset Buttons
ResetButtons(){
    DebugMessage("Resetting Panel Buttons...");
    integer NumLinks = llGetNumberOfPrims();
    integer i;
    ButtonLinks = [];
    ButtonNames = [];
    for(i=1;i<=NumLinks;i++){
        string Name = llGetLinkName(i);
        if(llList2String(llParseString2List(Name, [":"], []), 1)=="BUTTON"){
            ButtonNames = ButtonNames + [Name];
            DebugMessage("Button Name: "+llList2String(ButtonNames, -1)+" Added!");
            ButtonLinks = ButtonLinks + [ i ];
            DebugMessage("Button Link ID: "+llList2String(ButtonLinks, -1)+ "Added!");
            llSetLinkPrimitiveParamsFast( i, [
                PRIM_COLOR, ALL_SIDES, <255,255,255>, 1.0,
                PRIM_POINT_LIGHT, FALSE, <128,128,0>, 1.0, 0.7, 0.0,
                PRIM_GLOW, ALL_SIDES, 0.0,
                PRIM_FULLBRIGHT, ALL_SIDES, FALSE]
            );
        }
    }
}

// Change LED Display
Display(string Text){
    DebugMessage("Updating Internal LCD Display with: "+Text);
    if(llStringLength(Text)==2){
        Text = "  " + Text + "  ";
    }else if(llStringLength(Text)==1){
        Text = "  0" + Text + "  ";
    }else{
        Text = "  ??  ";
    }
    llMessageLinked(LINK_SET, 281000, Text, "''''");
}

// Add Floor to Floor Destination List
AddFloor(integer Floor){
    DestFloor = DestFloor + [Floor];
    DebugMessage("Added Floor: "+(string)Floor+" to Destination Floor List.");
}

// Main System Control Function
SystemCtl(string System, string CMD, integer LinkID){
    if(System=="Doors"){
        if(CMD=="Open"){
            llRegionSay(DoorChannel, "Open||"+(string)CurrentFloor);
        }else if(CMD=="Close"){
            llRegionSay(DoorChannel, "Close||"+(string)CurrentFloor);
        }
    }else if(System=="Car"){
        if(CMD=="Move"){
            if(LinkID<CurrentFloor){ // Next Move is Down
                DebugMessage("Going Down...");
                dest_floor = LinkID;
                integer DiF = (CurrentFloor - LinkID); // Number of Floors to Travel
                travelTime = (DiF * SpeedT); // TravelTime
                DiM = (llList2Float(Floors, CurrentFloor) - llList2Float(Floors, LinkID)); // Determine Distance in Meters
                DiM = DiM * -1;
                destPos = llGetPos();
                destPos.z = llList2Float(Floors, LinkID);
                nextfloor = llGetPos();
                nextfloor.z = llList2Float(Floors, (CurrentFloor - 1));
                llOwnerSay((string)DiM+"Next Floor:"+(string)llListFindList(Floors, [nextfloor.z])+"||"+(string)nextfloor.z);
                llWhisper(0, "Going Down, Please take a seat or be left behind...");
                RunMode = "MoveDown";
                TimerMode = "StartMoving";
                llSetTimerEvent(SitTimeOut);
            }else if(LinkID>CurrentFloor){ // Next Move is Up
                DebugMessage("Going Up...");
                dest_floor = LinkID;
                integer DiF = (LinkID - CurrentFloor); // Number of Floors to Travel
                travelTime = (DiF * SpeedT); // TravelTime
                DiM = (llList2Float(Floors, LinkID) - llList2Float(Floors, CurrentFloor)); // Travel Distance in Meters
                destPos = llGetPos();
                destPos.z = llList2Float(Floors, LinkID);
                nextfloor = llGetPos();
                nextfloor.z = llList2Float(Floors, (CurrentFloor + 1));
                llWhisper(0, "Going Up, Please take a seat or be left behind...");
                DebugMessage("LinkID: "+(string)LinkID+"\nDest Pos: "+(string)destPos.z+"Next Floor: "+(string)nextfloor.z);
                RunMode = "MoveUp";
                TimerMode = "StartMoving";
                llSetTimerEvent(SitTimeOut);
            }
        }
    }else if(System=="Button"){
        if(CMD=="On"){
            // Turn Button Light On
            llSetLinkPrimitiveParamsFast(LinkID, [
                PRIM_COLOR, ALL_SIDES, <255,255,0>, 1.0,
                PRIM_POINT_LIGHT, TRUE, <128,128,0>, 1.0, 0.7, 0.0,
                PRIM_GLOW, ALL_SIDES, 0.10,
                PRIM_FULLBRIGHT, ALL_SIDES, TRUE]
            );
        }else if(CMD=="Off"){
            llSetLinkPrimitiveParamsFast(LinkID, [
                PRIM_COLOR, ALL_SIDES, <255,255,255>, 1.0,
                PRIM_POINT_LIGHT, FALSE, <128,128,0>, 1.0, 0.7, 0.0,
                PRIM_GLOW, ALL_SIDES, 0.0,
                PRIM_FULLBRIGHT, ALL_SIDES, FALSE]
            );
            llRegionSay(OutCallButtonChannel, "ARRIVED||"+(string)CurrentFloor);
        }
    }
}

// Check Next Floor (Check if we have a next floor to go to. If so we go there and if not we mark as ready and leave the card on that floor
CheckNextFloor(){
    DebugMessage("Checking for Next Floor...");
    integer NumFloors = llGetListLength(DestFloor);
    if(NumFloors>0){
        integer NextFloor = llList2Integer(DestFloor, 0);
        DebugMessage("Found Next Floor "+(string)NextFloor);
        if(NextFloor==CurrentFloor){
            DebugMessage("Next Floor is Current Floor! Removing from List and recalling...");
            if(NumFloors==1){
                DestFloor = [];
            }else if(NumFloors>1){
                DestFloor = llList2List(DestFloor, 1, -1);
            }
            DebugMessage(llDumpList2String(DestFloor, "||"));
            CheckNextFloor();
        }else{
            SystemCtl("Car", "Move", NextFloor);
        }
    }else if(NumFloors==0){
        RunMode = "Ready";
        TimerMode = EMPTY;
        DebugMessage("Elevator Ready!");
    }
}

// Get Button Link ID From List (ButtonLinks) Based on iFloor
integer GetButtonLinkID(integer Floor){
    DebugMessage("In: "+(string)Floor);
    string ButtonName = (string)Floor+":BUTTON";
    integer LinkID = llList2Integer(ButtonLinks, llListFindList(ButtonNames, [ButtonName]));
    DebugMessage("Link ID: "+(string)LinkID);
    return LinkID;
}


//Main Program Logic
/* This section contains the main program logic. (ie: Default State, and all event triggers) */

default{
    on_rez(integer params){
        llResetScript();
    }
    
    state_entry(){
        Initialize();
    }
    
    listen(integer channel, string sender, key id, string msg){
        DebugMessage("Listen Fired: "+(string)msg);
        if(channel==ComChannel){
            list InputData = llParseString2List(msg, ["||"], []);
            if(llList2String(InputData, 0)==llGetKey()){
                if(llList2String(InputData, 1)=="CONFIG"){
                    ComChannel = llList2Integer(InputData, 2);
                    DebugMessage("New Com Channel: "+(string)ComChannel+" Closing old channel...");
                    llListenRemove(ComHandle);
                    ComHandle = 0;
                    DebugMessage("Opening New Channel...");
                    ComHandle = llListen(ComChannel, EMPTY, EMPTY, EMPTY);
                    if(ComHandle>0){
                        DebugMessage("New Com Channel ("+(string)ComChannel+") Open!");
                    }else{
                        DebugMessage("Could not open new com channel!");
                        return;
                    }
                    if(llList2String(InputData, 3)=="TRUE"){ OpMode = TRUE; }else{ OpMode = FALSE; }
                    if(OpMode){
                        DebugMessage("Elevator Starting in Online Mode!");
                        RunMode = "Ready";
                    }else{
                        DebugMessage("Elevator Starting in Offline Mode!");
                        RunMode = "Offline";
                    }
                    SpeedT = llList2Float(InputData, 4);
                    DebugMessage("Speed: "+(string)SpeedT);
                    SitTimeOut = llList2Float(InputData, 5);
                    DebugMessage("SitTimeOut: "+(string)SitTimeOut);
                    OutCallButtonChannel = llList2Integer(InputData, 6);
                    DebugMessage("OutCallButton Channel: "+(string)OutCallButtonChannel);
                    integer i;
                    list TempFloors = llList2List(InputData, 7, -1);
                    for(i=0;i<llGetListLength(TempFloors);i++){
                        Floors = Floors + [llList2Float(TempFloors, i)];
                        DebugMessage("Registering Floor "+(string)(i + 1)+" Z-Axis as: "+(string)llList2String(Floors, -1));
                    }
                    ScanForSeats();
                }else if(llList2String(InputData, 1)=="GOTO"){
                    integer GotoFloor = llList2Integer(InputData, 2);
                    DebugMessage("Test");
                    if(GotoFloor==CurrentFloor && RunMode=="Ready"){
                        SystemCtl("Doors", "Open", GotoFloor);
                        integer Link = GetButtonLinkID(GotoFloor);
                        SystemCtl("Button", "Off", Link);
                        return;
                    }
                    if(RunMode=="Ready"){
                        SystemCtl("Car", "Move", GotoFloor);
                    }else{
                        AddFloor(GotoFloor);
                    }
                }
            }else{
                
            }
        }
    }
    
    // For Detecting Touched to Interal Control Panel, This way Avoiding using listeners.
    touch_start(integer num){
        integer TouchedLink = llDetectedLinkNumber(0);
        DebugMessage("Link Touched: "+(string)TouchedLink);
        string ButtonName = llGetLinkName(TouchedLink);
        list ButtonProperty = llParseString2List(ButtonName, [":"], []);
        string CMD = llList2String(ButtonProperty, 0);
        string LINKTYPE = llList2String(ButtonProperty, 1);
        if(LINKTYPE!="BUTTON"){
            return;
        }
        
        SystemCtl("Button", "On", TouchedLink);
        
        if(CMD=="Open"){
            SystemCtl("Doors", "Open", 0);
            llSleep(1.0);
            SystemCtl("Button", "Off", TouchedLink);
        }else if(CMD=="Close"){
            SystemCtl("Doors", "Close", 0);
            llSleep(1.0);
            SystemCtl("Button", "Off", TouchedLink);
        }else{
            if(RunMode=="Offline"){
                llWhisper(0, "Elevator is Offline!");
                llSleep(2.0);
                SystemCtl("Button", "Off", TouchedLink);
            }else if(RunMode=="Ready"){
                if((integer)CMD==CurrentFloor){
                    SystemCtl("Doors","Open", 0);
                    llSleep(1.0);
                    SystemCtl("Button", "Off", TouchedLink);
                }else{
                    AddFloor((integer)CMD);
                    SystemCtl("Car", "Move", (integer)CMD);
                }
            }else{
                AddFloor((integer)CMD);
            }
        }
        //llOwnerSay("Link: "+(string)TouchedLink+" Name: "+ButtonName);
    }
    
     // DataServer Event Called for Each Line of Config NC. This Loop It was Calls LoadConfig()
    dataserver(key query_id, string data){       // Config Notecard Read Function Needs to be Finished
        if (query_id == cQueryID){
            if (data != EOF){ 
                LoadConfig(data); // Process Current Line
                ++cLine; // Increment Line Index
                cQueryID = llGetNotecardLine(ConfigFile, cLine); // Attempt to Read Next Config Line (Re-Calls DataServer Event)
            }else{ // IF EOF (End of Config loop, and on Blank File)
                DebugMessage("Asking Elevator Panel Server for Config...");
                string SendString = "GETCONFIG||ELEVATOR";
                llRegionSay(ComChannel, SendString);
            }
        }
    }
    
    changed(integer change){
        if(change & CHANGED_INVENTORY){
            BootMessage = "Inventory Changed Detected, Re-Initializing...";
            llResetScript();
        }
    }
    
    timer(){
        if(TimerMode=="StartMoving"){
            llSetKeyframedMotion(
                [<0.0,0.0,DiM>, travelTime],
                [KFM_DATA, KFM_TRANSLATION, KFM_MODE, KFM_FORWARD]
            );
            RunMode = "Moving";
            TimerMode = "Checking";
            llSetTimerEvent(1.0);
        }else if(TimerMode=="Checking"){
            vector currentPos = llGetPos();
            if(llRound(currentPos.z)==llRound(destPos.z)){ // We Have Arrived at the requested Floor
                CurrentFloor = dest_floor;
                Display((string)CurrentFloor);
                SystemCtl("Doors", "Open", CurrentFloor);
                llWhisper(0, "Arrived @ Floor "+(string)CurrentFloor);
                llSetTimerEvent(0);
                integer Link = GetButtonLinkID(CurrentFloor);
                SystemCtl("Button", "Off", Link);
                CheckNextFloor();
            }
            
            if(llRound(currentPos.z)==llRound(nextfloor.z)){ // We have Passed through intermediate floors on our way to dst
                if(dest_floor<CurrentFloor){ // We are moving down
                    CurrentFloor--;
                    nextfloor.z = llList2Float(Floors, (CurrentFloor - 1));
                    DebugMessage("Elevator Saw Floor "+(string)CurrentFloor+" Next Floor: "+(string)nextfloor.z);
                }else if(dest_floor>CurrentFloor){ // We are moving Up
                    CurrentFloor++;
                    nextfloor.z = llList2Float(Floors, (CurrentFloor + 1));
                    DebugMessage("Elevator Saw Floor "+(string)CurrentFloor+" Next Floor: "+(string)nextfloor.z);
                }
                Display((string)CurrentFloor);
                string SendString = "FLOOR||"+(string)CurrentFloor;
                llRegionSay(OutCallButtonChannel, SendString);
            }
        }
    }
}